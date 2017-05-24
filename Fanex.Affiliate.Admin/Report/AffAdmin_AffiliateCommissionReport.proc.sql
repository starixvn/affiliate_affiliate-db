USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateCommissionReport] 
	@LicenseeID			INT
	,@UserId 			INT 			= 0
	,@AffName 			NVARCHAR(100) 	= NULL
	,@AffTypes 			VARCHAR(100) 	= NULL
	,@CommGroups 		VARCHAR(1000) 	= NULL
	,@PreferLanguages 	VARCHAR(1000) 	= NULL
	,@Currencies 		VARCHAR(100) 	= NULL
	,@BaseCurrency 		TINYINT 		= 0
	,@SortBy 			TINYINT 		= 0
	,@ExcludeTest 		BIT 			= 1
	,@IsITAdmin 		BIT 			= 0
	,@ProductIds 		VARCHAR(100) 	= NULL
	--------Task:PlayerComm & Virtual Sport------
	,@TransferStatus	TINYINT			= 0 
	,@GroupBy			TINYINT			= 0 
	,@FromDate			DATETIME		= NULL
	,@ToDate			DATETIME		= NULL
	,@PageCurrent 		INT 			= 1
	,@PageSize 			INT 			= 25
	,@NRows 			INT 			= 0 	OUTPUT
	,@Error 			INT 			= 0 	OUTPUT
	,@Error_Msg 		NVARCHAR(100) 	= '' 	OUTPUT
AS

/*    
	Author: 20140825@Bobby.Nguyen
	Task: Affiliate Commission Report - Company View     
	DB: DBAFF.Affiliate_Athena000
	Original: [AffAdmin_CommissionSettle]

	Revisions:
		- 20140825@Bobby: Add Virtual Sport & PlayerComm - apply SQL stylecope
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
	Param's Explanation: 
		-@TransferStatus: 	0 - ALL, 1 - Is Processing, 2 - Transferred
		-@GroupBy:			0 - Affiliate, 1 - Affiliate & Month
		-@SortBy:			0 - Affiliate, 1 - Month (& @GroupBy = 1), 2 - Total Payment (Commission)
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	DECLARE @CurrentDate					DATETIME
		,@MaxCalculatedDate					DATETIME
		,@PreviousMonth						DATETIME
		,@PreviousMonthDate					DATETIME
		,@SystemExchangeId					INT
		,@IsForceMinNegativeCommission 		BIT = 0
		,@MinimumNegativeCommission 		FLOAT = 0.1

	DECLARE @ProductFilter 	TABLE ( ProductId	INT )
	DECLARE	@AffUserRpt 	TABLE ( AffId 		INT
								,Username 		NVARCHAR(30)
								,AffType 		VARCHAR(50)
								,LANGUAGE 		NVARCHAR(255)
								,ExchangeId 	INT
								,Currency 		VARCHAR(5)
								,STATUS 		VARCHAR(50)
								,MonthDate 		DATETIME
								,GroupId 		INT
								,GroupName 		NVARCHAR(100)
							)

	-- Assign date value
	SELECT @FromDate			= dbo.Aff_GetStartDate(@FromDate)
		,@ToDate				= dbo.Aff_GetEndDate(@ToDate)
		,@CurrentDate			= CURRENT_TIMESTAMP
		,@PreviousMonth			= dbo.Aff_GetLastDayOfMonth(DATEADD(m, - 1, @CurrentDate))
		,@SystemExchangeId		= [dbo].[Aff_GetSystemCurrencyID]()
		,@PreviousMonthDate		= CAST(@PreviousMonth AS DATE)

	SELECT @MaxCalculatedDate	= ISNULL(MAX(ac.WinlostDate), '2013-05-01')
	FROM dbo.AffCommission ac WITH(NOLOCK)

	-- product filtering
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT Val
		FROM [dbo].[strSplit_key](@ProductIds, ',')
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT p.ProductID
		FROM dbo.Product p WITH (NOLOCK)
	END
	
	-- check is NegativeCommission
	SELECT @MinimumNegativeCommission 		= CASE WHEN SName = 'AFF_MinNegativeCommission' THEN ISNULL(SValue, @MinimumNegativeCommission) ELSE @MinimumNegativeCommission END
			,@IsForceMinNegativeCommission 	= CASE WHEN SName = 'AFF_ForceMinNegativeCommission' THEN ISNULL(SValue, @IsForceMinNegativeCommission) ELSE @IsForceMinNegativeCommission END
	FROM dbo.SystemSettings with(nolock)
	WHERE SName IN ('AFF_ForceMinNegativeCommission', 'AFF_MinNegativeCommission')
			
	-- getlist affiliate user 
	INSERT INTO	@AffUserRpt
	SELECT AffId
		,Username
		,AffType
		,LANGUAGE
		,ExchangeId
		,Currency
		,STATUS
		,MonthDate
		,GroupId
		,GroupName
	FROM [dbo].[AffAdmin_AffiliateListForReport](@LicenseeID, @UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
	
	IF(NOT EXISTS(SELECT TOP 1 1 FROM @AffUserRpt))
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not avaiable affiliate user.'
		RETURN;
	END
	
	CREATE TABLE #AffCommissionRpt
	(
		AffId								INT
		,WinlostDate						SMALLDATETIME
		,GroupID							INT
		,ProductID							INT
		,ExchangeId							INT
		,NetWinlost							MONEY
		,TotalQM							INT
		,CommissionPercent					DECIMAL(9, 8)
		,Commission							MONEY
		,MemWinlost							MONEY
		----------sharing fee---------------------------
		,HasBonus 							BIT	
		,BonusPercent						FLOAT
		,MemBonus							MONEY
		,MemPSP								MONEY
		,MemPlayerComm						MONEY
		,ZeroCommission						BIT
	)
	
	--Is All|Transfered Commission
	IF(@FromDate <= @MaxCalculatedDate AND @TransferStatus IN (2, 0))
	BEGIN
		INSERT INTO #AffCommissionRpt
		(
			AffId
			,GroupID
			,ProductID
			,WinlostDate
			,ExchangeId
			,MemWinlost		
			,MemBonus
			,MemPSP					
			,MemPlayerComm						
		)
		SELECT ac.AffId
			,ac.GroupID
			,ac.ProductID
			,ac.WinlostDate							AS WinlostDate
			,t.ExchangeId							AS ExchangeId
			,ac.MemberWinlost_aff				 	AS MemWinlost
			,ac.MemberBonus_aff				 		AS MemBonus
			,ac.MemberPSP_aff				 		AS MemPSP
			,ac.PlayerComm_aff 						AS MemPlayerComm
		FROM [dbo].[AffCommission] ac WITH(NOLOCK)
			INNER JOIN @AffUserRpt t ON ac.AffID = t.AffId AND ac.Winlostdate = t.MonthDate
			INNER JOIN @ProductFilter p ON ac.ProductId = p.ProductId
		WHERE ac.Winlostdate BETWEEN @FromDate AND @MaxCalculatedDate
	END
		
	--Is All|Processing Commission
	IF(@ToDate > @MaxCalculatedDate AND @TransferStatus	IN (1, 0))
	BEGIN
		INSERT INTO #AffCommissionRpt
		(
			AffId
			,GroupID
			,ProductID
			,WinlostDate
			,ExchangeId
			,MemWinlost		
			,MemBonus
			,MemPSP					
			,MemPlayerComm						
		)
		SELECT ad.AffId
			,t.GroupID
			,ad.ProductID
			,t.MonthDate 							AS WinlostDate
			,t.ExchangeId							AS ExchangeId
			,SUM(ISNULL(ad.MemWinlost_aff, 0)) 		AS MemWinlost
			,SUM(ISNULL(ad.MemBonus_aff, 0)) 		AS MemBonus
			,SUM(ISNULL(ad.MemPSP_aff, 0)) 			AS MemPSP
			,SUM(ISNULL(ad.MemPlayerComm_aff, 0)) 	AS MemPlayerComm
		FROM dbo.AffDailySummary ad WITH (NOLOCK)
			INNER JOIN @AffUserRpt t ON ad.AffID = t.AffId AND DATEDIFF(M, ad.Winlostdate, t.MonthDate) = 0
			INNER JOIN @ProductFilter p ON ad.ProductId = p.ProductId
		WHERE ad.Winlostdate > @MaxCalculatedDate AND ad.Winlostdate <= @ToDate
		GROUP BY ad.AffId
			,t.MonthDate
			,t.ExchangeId
			,t.GroupID
			,ad.ProductID
	END
	
	IF(NOT EXISTS(SELECT TOP 1 1 FROM #AffCommissionRpt))
	BEGIN 
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not avaiable data.'
		RETURN
	END
	
	;WITH AffCommGroup AS (
		SELECT rpt.AffID
			, rpt.WinlostDate
			, rpt.GroupID
			, rpt.ProductID
			, dbo.[Aff_GetQMTurnOver](rpt.AffId, rpt.WinlostDate) AS QMAmount
		FROM #AffCommissionRpt rpt
		GROUP BY rpt.AffID
			, rpt.WinlostDate
			, rpt.GroupID
			, rpt.ProductID
	)
	,AffSharingFee AS (
		SELECT rpt.AffId
			,rpt.WinlostDate
			,rpt.GroupID
			,rpt.ProductID
			,qm.TotalQM
			,dbo.AffAdmin_f_HasDeduction(rpt.GroupID, rpt.ProductID, 'Bonus', rpt.WinlostDate) AS HasBonus
			,dbo.AffAdmin_f_HasDeduction(rpt.GroupID, rpt.ProductID, 'Marketing', rpt.WinlostDate) AS HasMarketing
			,dbo.AffAdmin_f_HasDeduction(rpt.GroupID, rpt.ProductID, 'PSP', rpt.WinlostDate) AS HasPSP
			,dbo.AffAdmin_f_HasDeduction(rpt.GroupID, rpt.ProductID, 'Odds Fee', rpt.WinlostDate) AS HasOddsFee
			,dbo.AffAdmin_f_HasDeduction(rpt.GroupID, rpt.ProductID, 'PlayerComm', rpt.WinlostDate) AS HasPlayerComm
			,dbo.AffAdmin_f_GetDeductionPercent(rpt.AffID, rpt.ProductID, 'Bonus', rpt.WinlostDate) AS BonusPercent
			,dbo.AffAdmin_f_GetDeductionPercent(rpt.AffID, rpt.ProductID, 'Marketing', rpt.WinlostDate) AS MarketingPercent
			,dbo.AffAdmin_f_GetDeductionPercent(rpt.AffID, rpt.ProductID, 'PSP', rpt.WinlostDate) AS PSPPercent
			,dbo.AffAdmin_f_GetDeductionPercent(rpt.AffID, rpt.ProductID, 'Odds Fee', rpt.WinlostDate) AS OddsFeePercent
			,dbo.AffAdmin_f_GetDeductionPercent(rpt.AffID, rpt.ProductID, 'PlayerComm', rpt.WinlostDate) AS PlayerCommPercent
			,[dbo].[IsZeroCommissionGroup](rpt.GroupID, rpt.WinlostDate) AS ZeroCommission
		FROM AffCommGroup rpt
			CROSS APPLY (
				SELECT COUNT(1) AS TotalQM
				FROM (
					SELECT UserName
					FROM dbo.MemberDaily md WITH(NOLOCK)
					WHERE md.AffID 			= rpt.AffID
						AND md.ProductID 	= rpt.ProductID
						AND DATEDIFF(M, md.WinlostDate, rpt.WinlostDate) = 0
					GROUP BY UserName
					HAVING SUM(ISNULL(md.TurnOver, 0) * ISNULL(md.AffExRate, 1)) >= rpt.QMAmount
				) r
			) qm

	)
	UPDATE rpt 
	SET rpt.NetWinlost 			= (- ISNULL(rpt.MemWinlost, 0)
									- CAST(sf.HasPSP AS INT) * ISNULL(rpt.MemPSP, 0) * ISNULL(sf.PSPPercent, 1) 
									- CAST(sf.HasOddsFee AS INT) * ABS(ISNULL(rpt.MemWinlost, 0)) * ISNULL(sf.OddsFeePercent, 1) 
									- CAST(sf.HasMarketing AS INT) * ABS(ISNULL(rpt.MemWinlost, 0)) * ISNULL(sf.MarketingPercent, 1) 
									- CAST(sf.HasPlayerComm AS INT) * ABS(ISNULL(rpt.MemPlayerComm, 0)) * ISNULL(sf.PlayerCommPercent, 1))
		,rpt.TotalQM 			= sf.TotalQM
		,rpt.HasBonus 			= sf.HasBonus
		,rpt.BonusPercent 		= sf.BonusPercent
		,rpt.ZeroCommission		= sf.ZeroCommission
	FROM #AffCommissionRpt rpt
		INNER JOIN AffSharingFee sf
		ON rpt.AffId			= sf.AffId
			AND rpt.ProductID	= sf.ProductID
			AND rpt.GroupID		= sf.GroupID
			AND rpt.WinlostDate	= sf.WinlostDate
	
	-- remove NetWinlost is zero and No bonus
	DELETE rpt
	FROM #AffCommissionRpt rpt
	WHERE rpt.NetWinlost = 0
		AND (rpt.BonusPercent * rpt.MemBonus) = 0
	
	;WITH CommPercent AS (
		SELECT rpt.AffId
			, rpt.GroupID
			, rpt.ProductID
			, rpt.WinlostDate
			, ch.CommPercent
		FROM #AffCommissionRpt rpt
			CROSS APPLY (
				SELECT TOP (1) ISNULL(t.Commission, 0) AS CommPercent
				FROM (
					------------current group setting --------------
					SELECT gs.Commission
					FROM dbo.GroupSetting gs WITH(NOLOCK)
					WHERE gs.GroupID 		= rpt.GroupID
						AND gs.ProductID 	= rpt.ProductID
						AND (FLOOR(ABS(rpt.NetWinlost)) BETWEEN gs.MinAmount AND gs.MaxAmount)
						AND DATEDIFF(M, rpt.WinlostDate, @CurrentDate) = 0
					
					UNION ALL
					SELECT TOP (1) gs.Commission
					FROM dbo.GroupSetting gs WITH(NOLOCK)
					WHERE gs.GroupID 		= rpt.GroupID
						AND gs.ProductID 	= rpt.ProductID
						AND rpt.TotalQM BETWEEN gs.MinQM AND gs.MaxQM
						AND DATEDIFF(M, rpt.WinlostDate, @CurrentDate) = 0
					
					------------history group setting --------------
					UNION ALL
					SELECT gh.Commission
					FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
					WHERE gh.GroupID 		= rpt.GroupID
						AND gh.ProductID 	= rpt.ProductID
						AND DATEDIFF(M, gh.MonthDate, rpt.WinlostDate) = 0
						AND (FLOOR(ABS(rpt.NetWinlost)) BETWEEN gh.MinAmount AND gh.MaxAmount)
					
					UNION ALL
					SELECT TOP (1) gh.Commission
					FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
					WHERE gh.GroupID 		= rpt.GroupID
						AND gh.ProductID 	= rpt.ProductID
						AND DATEDIFF(M, gh.MonthDate, rpt.WinlostDate) = 0
						AND rpt.TotalQM BETWEEN gh.MinQM AND gh.MaxQM
				) t
				ORDER BY t.Commission ASC
			) ch
		GROUP BY rpt.AffId
			, rpt.GroupID
			, rpt.ProductID
			, rpt.WinlostDate
			, ch.CommPercent
	)
	UPDATE rpt 
	SET rpt.CommissionPercent = comm.CommPercent
	FROM #AffCommissionRpt rpt
		INNER JOIN CommPercent comm
		ON rpt.AffId			= comm.AffId
			AND rpt.GroupID		= comm.GroupID
			AND rpt.ProductID	= comm.ProductID
			AND rpt.WinlostDate	= comm.WinlostDate
		
	-- update zero-comm
	UPDATE rpt
	SET rpt.CommissionPercent = @MinimumNegativeCommission
	FROM #AffCommissionRpt rpt
	WHERE rpt.NetWinlost < 0
		AND rpt.ZeroCommission 		= 0 -- NOT a Zero Commission Group
		AND (rpt.CommissionPercent  = 0 OR @IsForceMinNegativeCommission = 1)
		AND rpt.ProductID IN (
			SELECT ProductID 
			FROM (
				SELECT gs.ProductID
				FROM dbo.GroupSetting gs WITH(NOLOCK)
				WHERE gs.GroupID = rpt.GroupID
					AND DATEDIFF(m, rpt.WinlostDate, @CurrentDate) = 0
				
				UNION
				SELECT gh.ProductID
				FROM dbo.GroupSettingHistory gh WITH(NOLOCK)
				WHERE gh.GroupID = rpt.GroupID
					AND DATEDIFF(m, gh.MonthDate, rpt.WinlostDate) = 0
			
			) AS t
			GROUP BY t.ProductID
		)

	-- update final netwinloss
	UPDATE rpt
	SET rpt.Commission = ((rpt.NetWinlost - (CAST(rpt.HasBonus AS INT) * ISNULL(rpt.MemBonus, 0) * ISNULL(rpt.BonusPercent, 1))) * ISNULL(rpt.CommissionPercent, 0)) * CASE 
			WHEN rpt.ZeroCommission = 1 THEN 0
			ELSE 1
			END
	FROM #AffCommissionRpt rpt

	---- AFF Pagging
	SELECT 
		rpt.AffID
		,ai.UserName
		,CASE WHEN @GroupBy = 1 THEN rpt.WinlostDate 	ELSE 0 		END AS WinlostDate
		,CASE WHEN @GroupBy = 1 THEN rpt.GroupId 		ELSE 0 		END AS GroupId
		,CASE WHEN @GroupBy = 1 THEN ai.GroupName  		ELSE '-' 	END AS GroupName
		,ai.ExchangeId
		,ai.Currency
		,SUM(ISNULL(rpt.Commission, 0)) AS TotalPayment
		,ROW_NUMBER() OVER ( 
				ORDER BY 
					CASE 	WHEN @SortBy = 0 	THEN ai.UserName 				END ASC
					, CASE 	WHEN @SortBy = 1 	THEN MAX(rpt.WinlostDate) 		END ASC
					, CASE 	WHEN @SortBy = 2 AND @BaseCurrency = 0 
												THEN SUM(ISNULL(Commission, 0)) 
						END DESC
					, CASE 	WHEN @SortBy = 2 AND @BaseCurrency = 1 
												THEN (SUM(ISNULL(Commission, 0)) * dbo.Aff_GetExchangeRate(ai.ExchangeId, @SystemExchangeId, NULL))
						END DESC
					, CASE 	WHEN @SortBy <> 0 	THEN ai.UserName 				END ASC
					, CASE 	WHEN @SortBy <> 1 	THEN MAX(rpt.WinlostDate)  		END ASC
		) AS RowIDX
	INTO #AffCommPaging
	FROM #AffCommissionRpt rpt
		INNER JOIN @AffUserRpt ai ON rpt.AffID = ai.AffId AND rpt.Winlostdate = ai.MonthDate
	GROUP BY 
		rpt.AffID
		,ai.UserName
		,CASE WHEN @GroupBy = 1 THEN rpt.WinlostDate 	ELSE 0 		END
		,CASE WHEN @GroupBy = 1 THEN rpt.GroupId 		ELSE 0 		END
		,CASE WHEN @GroupBy = 1 THEN ai.GroupName  		ELSE '-' 	END
		,ai.ExchangeId
		,ai.Currency
	
	--select PageTotal
	SELECT @NRows = COUNT(1) FROM #AffCommPaging

	SELECT r.RowIDX
		,r.AffID
		,r.UserName
		,r.WinlostDate
		,r.GroupId
		,r.GroupName
		,r.Currency
		,rpt.ProductId
		,p.ProductName
		,SUM(rpt.NetWinlost) 					AS NetWinlost
		,SUM(rpt.NetWinlost
				* dbo.Aff_GetExchangeRate(r.ExchangeId, @SystemExchangeId, NULL)) 
												AS NetWinlostBase
		,SUM(rpt.TotalQM)						AS TotalQM
		,SUM(rpt.CommissionPercent)			 	AS CommissionPercent
		,SUM(rpt.Commission)		 			AS Commission
		,SUM(rpt.Commission
				* dbo.Aff_GetExchangeRate(r.ExchangeId, @SystemExchangeId, NULL)) 
												AS CommissionBase
		,r.TotalPayment
		,(r.TotalPayment 
				* dbo.Aff_GetExchangeRate(r.ExchangeId, @SystemExchangeId, NULL)) 
												AS TotalPaymentBase
	FROM #AffCommPaging r
		INNER JOIN #AffCommissionRpt rpt ON r.AffId = rpt.AffId AND (r.WinlostDate = 0 OR r.WinlostDate = rpt.WinlostDate)
		INNER JOIN dbo.Product p WITH(NOLOCK) ON rpt.ProductId = p.ProductId
	WHERE r.RowIDX BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
	GROUP BY r.RowIDX
		,r.AffID
		,r.UserName
		,r.WinlostDate
		,r.GroupId
		,r.GroupName
		,r.ExchangeId
		,r.Currency
		,r.TotalPayment
		,rpt.ProductId
		,p.ProductName
	ORDER BY r.RowIDX
		, rpt.ProductId
	
	--SUM by Currecy + Product
	;WITH SumCurrency AS (
		SELECT r.ExchangeId
			,r.Currency
			,SUM(r.TotalPayment)					AS TotalPayment
			,SUM(r.TotalPayment 
				* dbo.Aff_GetExchangeRate(r.ExchangeId, @SystemExchangeId, NULL)) 
												AS TotalPaymentBase
		FROM #AffCommPaging r
		GROUP BY r.ExchangeId
			, r.Currency
	)
	SELECT s.Currency
		,rpt.ProductId
		,p.ProductName
		,SUM(rpt.NetWinlost) 					AS NetWinlost
		,SUM(rpt.NetWinlost
				* dbo.Aff_GetExchangeRate(rpt.ExchangeId, @SystemExchangeId, NULL)) 
												AS NetWinlostBase
		,SUM(rpt.TotalQM)						AS TotalQM
		,SUM(rpt.CommissionPercent)			 	AS CommissionPercent
		,SUM(rpt.Commission)		 			AS Commission
		,SUM(rpt.Commission
				* dbo.Aff_GetExchangeRate(rpt.ExchangeId, @SystemExchangeId, NULL)) 
												AS CommissionBase
		,s.TotalPayment
		,s.TotalPaymentBase
	FROM SumCurrency s
		INNER JOIN #AffCommissionRpt rpt ON s.ExchangeId = rpt.ExchangeId
		INNER JOIN dbo.Product p WITH(NOLOCK) ON rpt.ProductId = p.ProductId
	GROUP BY s.Currency
		,rpt.ProductId
		,p.ProductName
		,s.TotalPayment
		,s.TotalPaymentBase
	ORDER BY s.Currency
		,rpt.ProductId
		
	
	--SUM by Product
	;WITH SumProduct AS (
		SELECT 
			SUM(r.TotalPayment) AS TotalPayment
			, SUM (r.TotalPayment * dbo.Aff_GetExchangeRate(r.ExchangeId, @SystemExchangeId, NULL))  AS TotalPaymentBase
		FROM #AffCommPaging r
	)
	SELECT rpt.ProductId
		,p.ProductName
		,SUM(rpt.NetWinlost) 					AS NetWinlost
		,SUM(rpt.NetWinlost
				* dbo.Aff_GetExchangeRate(rpt.ExchangeId, @SystemExchangeId, NULL)) 
												AS NetWinlostBase
		,SUM(rpt.TotalQM)						AS TotalQM
		,SUM(rpt.CommissionPercent)			 	AS CommissionPercent
		,SUM(rpt.Commission)		 			AS Commission
		,SUM(rpt.Commission
				* dbo.Aff_GetExchangeRate(rpt.ExchangeId, @SystemExchangeId, NULL)) 
												AS CommissionBase
		,t.TotalPayment
		,t.TotalPaymentBase
	FROM #AffCommissionRpt rpt
		INNER JOIN dbo.Product p WITH(NOLOCK) ON rpt.ProductId = p.ProductId
		CROSS APPLY SumProduct t
	GROUP BY rpt.ProductId
		,p.ProductName
		,t.TotalPayment
		,t.TotalPaymentBase
	ORDER BY rpt.ProductId
		
	DROP TABLE #AffCommPaging
	DROP TABLE #AffCommissionRpt
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateCommissionReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateCommissionReport] TO [vnteam] AS [dbo]
GO