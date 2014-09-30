ALTER PROCEDURE [dbo].[AffAdmin_MemberWinLossReport] 
	@UserId 				INT 			= 0
	,@AffName 				NVARCHAR(100) 	= NULL
	,@AffTypes 				VARCHAR(100) 	= NULL
	,@CommGroups 			VARCHAR(1000) 	= NULL
	,@PreferLanguages 		VARCHAR(1000) 	= NULL
	,@PlayerName 			NVARCHAR(100) 	= NULL
	,@GroupBy 				TINYINT 		= 0
	,@FromDate 				DATETIME 		= NULL
	,@ToDate 				DATETIME 		= NULL
	,@PlayerCurrencies 		VARCHAR(100) 	= NULL
	,@BaseCurrency 			TINYINT 		= 0
	,@DrawFilter 			TINYINT 		= 0
	,@ExcludeTest 			BIT 			= 1
	,@IsITAdmin 			BIT 			= 0
	,@PageCurrent 			INT 			= 1
	,@PageSize 				INT 			= 25
	,@ProductIds 			VARCHAR(100) 	= NULL
	,@NRows 				INT 			= 0 	OUTPUT
	,@Error 				INT 			= 0 	OUTPUT
	,@Error_Msg 			NVARCHAR(100) 	= '' 	OUTPUT
AS
/*  Author:20140827@Bobby.Nguyen
	Task: Member Win Loss Report     
	DB:	DBAFFATHENA000\Affiliate_Athena000 
	Original:[AffAdmin_PlayerWinlossReport]
	Revisions:           
		- 20140827@Bobby: Add Virtual Sport & PlayerComm - apply style-scope
                
	Param's Explanation: 
	• @UserId: Admin user id
	• @AffName: Affiliate username
	• @AffTypes: List affilaite type
	• @CommGroups: List Commission group
	• @PreferLanguages: list preference language
	• @GroupBy: by date or month (0: by date; 1: by Member)
	• @FromDate: From date
	• @ToDate: To date
	• @DrawFilter: Bet Count & Turnover filter 
		- 0: "Normal" Betcount and turnover are included
		- 1: "No Draw" The Betcount will be exluded Draw tickets. The turnover will exclude draw & half draw tickets.
		- 2: "No Draw For Turnover Only" The Betcount will be included Draw tickets. The turnover will exclude draw & half draw tickets.
	• @BaseCurrency: The current exchange rate will be used if we wanna convert the affiliate's currency to system currency
		- 0: Original
		- 1: Convert to System Currency.
	• @ExcludeTest: not include test accounts if true.
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate 	DATETIME
		,@PlaytechCasino 	INT
		,@RptByAff			BIT = 0
		
	DECLARE @ProductFilter 	TABLE (ProductId INT)
	DECLARE @MemCurrencies 	TABLE ( ExchangeId SMALLINT, Currency VARCHAR(10) )
	DECLARE @AffUserRpt 	TABLE (
		AffId 				INT
		,Username 			NVARCHAR(30)
		,AffType 			VARCHAR(50)
		,ExchangeId 		INT
		,Currency 			VARCHAR(5)
		,MonthDate 			DATETIME
		,GroupId 			INT
		,GroupName 			NVARCHAR(100)
	);
	--Reset todate to ending of date
	SELECT @CurrentDate = GETDATE()
		, @FromDate		= CASE WHEN @FromDate IS NULL THEN dbo.Aff_GetFirstDayOfMonth(@CurrentDate) 
								ELSE dbo.Aff_GetStartDate(@FromDate) 
							END
		, @ToDate		= CASE WHEN @ToDate IS NULL OR @ToDate > @CurrentDate THEN @CurrentDate 
							ELSE dbo.Aff_GetEndDate(ISNULL(@ToDate, @CurrentDate)) 
							END
		,@PlayerName 	= '%' + ISNULL(@PlayerName, '') + '%'

	-- Get productid
	SELECT @PlaytechCasino	= p.ProductID
	FROM dbo.Product p WITH(NOLOCK)
	WHERE p.ProductName = 'Playtech Casino'

	--product filtering
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT Val
		FROM [dbo].[strSplit_key](@ProductIds, ',')
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT ProductId
		FROM dbo.Product WITH (NOLOCK)
	END

	--currency filtering
	INSERT INTO @MemCurrencies(ExchangeId, Currency)
	SELECT ex.ExchangeId
		,ex.Code
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN dbo.Exchange ex WITH (NOLOCK)
		ON tmp.Val = ex.ExchangeId
	
	-- affiliate user filterring
	INSERT INTO @AffUserRpt
	SELECT AffId
		,Username
		,AffType
		,ExchangeId
		,Currency
		,MonthDate
		,GroupId
		,GroupName
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

	IF( NOT EXISTS(SELECT TOP 1 1 FROM @AffUserRpt))
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not available affiliate user.'
		RETURN;
	END
	ELSE
	BEGIN
		SET @RptByAff = CAST (CASE 
							WHEN LEN(@AffName) > 0 AND (SELECT COUNT(DISTINCT UserName) FROM @AffUserRpt) = 1 THEN 1 
							ELSE @RptByAff 
						END AS BIT)
	END
	
	;WITH MemberWinLossRpt AS (
		SELECT 
			CASE WHEN @GroupBy = 0 THEN md.WinlostDate	
					ELSE 0 
				END 							AS WinlostDate
			,md.AffID
			,ai.Username 						AS AffUserName
			,ex.Code 							AS AffCurrency
			,md.Username 						AS PlayerUsername
			,mc.Currency 						AS PlayerCurrency
			,CASE WHEN @GroupBy = 0 THEN md.SysExRate 
					ELSE 1
				END 							AS SysExRate
			,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate 
					ELSE 1
				END 							AS AffExRate
		----------------------SUMDATA-------------------------------------
			,SUM(ISNULL(md.Deposit, 0)) 		AS Deposit
			,SUM(ISNULL(md.Deposit, 0)
				* md.AffExRate) 				AS Deposit_aff
			,SUM(ISNULL(md.Deposit, 0)
				* md.SysExRate) 				AS DepositBase
			,SUM(ISNULL(md.Withdrawal, 0))		AS Withdrawal
			,SUM(ISNULL(md.Withdrawal, 0)
				* md.AffExRate)					AS Withdrawal_aff
			,SUM(ISNULL(md.Withdrawal, 0)
				* md.SysExRate)					AS WithdrawalBase
			,SUM(ISNULL(md.PSP, 0))				AS PSP
			,SUM(ISNULL(md.PSP, 0)
				* md.AffExRate)					AS PSP_aff
			,SUM(ISNULL(md.PSP, 0)
				* md.SysExRate)					AS PSPBase
			,SUM(ISNULL(md.Bonus, 0))			AS Bonus
			,SUM(ISNULL(md.Bonus, 0)
				* md.AffExRate)					AS Bonus_aff
			,SUM(ISNULL(md.Bonus, 0)
				* md.SysExRate)					AS BonusBase
			,SUM(ISNULL(md.Adjustment, 0))		AS Adjustment
			,SUM(ISNULL(md.Adjustment, 0)
				* md.AffExRate)					AS Adjustment_aff
			,SUM(ISNULL(md.Adjustment, 0)
				* md.SysExRate)					AS AdjustmentBase
			,SUM(CASE WHEN @DrawFilter = 1 THEN ISNULL(md.BetCountNoDraw, 0)
						ELSE ISNULL(md.BetCount, 0)
				END)							AS BetCount
			
			,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
						ELSE ISNULL(md.TurnoverNoDraw, 0)
					END)						AS TotalTurnover
			,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
						ELSE ISNULL(md.TurnoverNoDraw, 0)
					END
				* md.AffExRate)					AS TotalTurnover_aff
			,SUM(CASE WHEN @DrawFilter = 0 THEN ISNULL(md.Turnover, 0)
						ELSE ISNULL(md.TurnoverNoDraw, 0)
					END
				* md.SysExRate)					AS TotalTurnoverBase
			,SUM(ISNULL(md.PlayerComm, 0))		AS PlayerComm
			,SUM(ISNULL(md.PlayerComm, 0)
				* md.AffExRate)					AS PlayerComm_aff
			,SUM(ISNULL(md.PlayerComm, 0)
				* md.SysExRate)					AS PlayerCommBase
			,SUM(ISNULL(md.Winlost, 0))			AS TotalWinlost
			,SUM(ISNULL(md.Winlost, 0)
				* md.AffExRate)					AS TotalWinlost_aff
			,SUM(ISNULL(md.Winlost, 0)
				* md.SysExRate)					AS TotalWinlostBase
			----------------------PWin,PShare & NetGmaing----------------------
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
					ELSE 0 
				END) 							AS PWin
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
					ELSE 0 
				END * md.AffExRate)				AS PWin_aff
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PWin, 0)
					ELSE 0 
				END * md.SysExRate)				AS PWinBase
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
					ELSE 0 
				END) 							AS PShare
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
					ELSE 0 
				END * md.AffExRate)				AS PShare_aff
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN ISNULL(md.PShare, 0)
					ELSE 0 
				END * md.SysExRate)				AS PShareBase
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
					ELSE 0
				END) AS NetGaming
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
					ELSE 0
				END * md.AffExRate) 			AS NetGaming_aff
			,SUM(CASE WHEN md.ProductID = @PlaytechCasino THEN (-ISNULL(md.Winlost, 0) - ISNULL(md.PShare, 0))
					ELSE 0
				END * md.SysExRate) 			AS NetGamingBase
				
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @AffUserRpt ai
			ON md.AffID = ai.AffID
				AND DATEDIFF(M, md.WinlostDate, ai.MonthDate) = 0
			INNER JOIN @ProductFilter p
			ON md.ProductID = p.ProductID
			INNER JOIN @MemCurrencies mc
			ON md.Currency = mc.ExchangeId
			INNER JOIN dbo.Exchange ex WITH (NOLOCK)
			ON md.AffCurrency = ex.ExchangeID
		WHERE md.WinlostDate BETWEEN @FromDate AND @ToDate
			AND md.UserName LIKE @PlayerName
		GROUP BY 
			CASE WHEN @GroupBy = 0 THEN md.WinlostDate	ELSE 0 END
			,md.AffID
			,ai.Username
			,ex.Code
			,md.Username
			,mc.Currency
			,CASE WHEN @GroupBy = 0 THEN md.SysExRate 
					ELSE 1
				END
			,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN md.AffExRate 
					ELSE 1
				END
	)
	,rptAffpaging AS (
		SELECT rpt.WinlostDate
			,rpt.AffID
			,rpt.AffUserName
			,rpt.AffCurrency
			,rpt.SysExRate
			,rpt.AffExRate
			,ROW_NUMBER() OVER (
				ORDER BY rpt.WinlostDate ASC
						,rpt.AffUserName ASC
			) AS RowIDX
		FROM MemberWinLossRpt AS rpt
		GROUP BY rpt.WinlostDate
			,rpt.AffID
			,rpt.AffUserName
			,rpt.AffCurrency
			,rpt.SysExRate
			,rpt.AffExRate
		HAVING SUM(rpt.Deposit) 	> 0
			OR SUM(rpt.TotalWinlost) 	> 0
			OR SUM(rpt.Bonus) 		> 0
			OR SUM(rpt.Adjustment)	> 0
			OR SUM(rpt.TotalTurnover) 	> 0
	)
	SELECT p.RowIDX
		,p.WinlostDate
		,p.AffID
		,p.AffUsername 	AS UserName
		,p.AffCurrency 	AS Currency
		,p.SysExRate 	AS ExRate
		,p.AffExRate
		,rpt.PlayerUsername
		,rpt.PlayerCurrency
		----------------------SUMDATA-------------------------------------
		,Deposit
		,Deposit_aff
		,DepositBase
		,Withdrawal
		,Withdrawal_aff
		,WithdrawalBase
		,PSP
		,PSP_aff
		,PSPBase
		,Bonus
		,Bonus_aff
		,BonusBase
		,Adjustment
		,Adjustment_aff
		,AdjustmentBase
		,BetCount
		,TotalTurnover
		,TotalTurnover_aff
		,TotalTurnoverBase
		,PlayerComm
		,PlayerComm_aff
		,PlayerCommBase
		,TotalWinlost
		,TotalWinlost_aff
		,TotalWinlostBase
		----------------------PWin,PShare & NetGmaing----------------------
		,PWin
		,PWin_aff
		,PWinBase
		,PShare
		,PShare_aff
		,PShareBase
		,NetGaming
		,NetGaming_aff
		,NetGamingBase
		
	INTO #WinLossPaging
	FROM rptAffpaging p
		INNER JOIN MemberWinLossRpt rpt
		ON p.AffID = rpt.AffID 
			AND p.WinlostDate = rpt.WinlostDate
	ORDER BY p.RowIDX
	
	--set @NRows
	SELECT @NRows = COUNT(DISTINCT rpt.RowIDX)
	FROM #WinLossPaging rpt
	
	--select data / page
	SELECT rpt.RowIDX
		,rpt.Winlostdate
		,rpt.UserName
		,rpt.Currency
		,rpt.PlayerUsername
		,rpt.PlayerCurrency
		,rpt.ExRate
		,rpt.AffExRate
		,rpt.Deposit
		,rpt.Deposit_aff
		,rpt.DepositBase
		,rpt.Withdrawal
		,rpt.Withdrawal_aff
		,rpt.WithdrawalBase
		,rpt.PSP
		,rpt.PSP_aff
		,rpt.PSPBase
		,rpt.Bonus
		,rpt.Bonus_aff
		,rpt.BonusBase
		,rpt.Adjustment
		,rpt.Adjustment_aff
		,rpt.AdjustmentBase
		,rpt.BetCount
		,rpt.TotalTurnover
		,rpt.TotalTurnover_Aff
		,rpt.TotalTurnoverBase
		,rpt.PlayerComm
		,rpt.PlayerComm_aff
		,rpt.PlayerCommBase
		,rpt.TotalWinlost		AS MemberWinLoss
		,rpt.TotalWinlost_Aff	AS MemberWinLoss_Aff
		,rpt.TotalWinlostBase	AS MemberWinLossBase
		,rpt.PWin
		,rpt.PWin_aff
		,rpt.PWinBase
		,rpt.PShare
		,rpt.PShare_aff
		,rpt.PShareBase
		,rpt.NetGaming		
		,rpt.NetGaming_aff
		,rpt.NetGamingBase
	FROM #WinLossPaging rpt
	WHERE rpt.RowIDX BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
	ORDER BY rpt.RowIDX 	ASC
		,rpt.PlayerUsername ASC
		
	--select sum data - PlayerCurrency
	SELECT PlayerCurrency
		----------------------SUMDATA-----------------------------------
		,SUM(Deposit) 						AS Deposit
		,SUM(Deposit_Aff) 					AS Deposit_Aff
		,SUM(DepositBase) 					AS DepositBase
		,SUM(Withdrawal) 					AS Withdrawal
		,SUM(Withdrawal_Aff) 				AS Withdrawal_Aff
		,SUM(WithdrawalBase) 				AS WithdrawalBase
		,SUM(PSP) 							AS PSP
		,SUM(PSP_Aff) 						AS PSP_Aff
		,SUM(PSPBase) 						AS PSPBase
		,SUM(Bonus) 						AS Bonus
		,SUM(Bonus_Aff) 					AS Bonus_Aff
		,SUM(BonusBase) 					AS BonusBase
		,SUM(Adjustment) 					AS Adjustment
		,SUM(Adjustment_Aff) 				AS Adjustment_Aff
		,SUM(AdjustmentBase) 				AS AdjustmentBase
		,SUM(BetCount) 						AS BetCount
		,SUM(TotalTurnover) 				AS TotalTurnover
		,SUM(TotalTurnover_Aff) 			AS TotalTurnover_Aff
		,SUM(TotalTurnoverBase) 			AS TotalTurnoverBase
		,SUM(PlayerComm)					AS PlayerComm
		,SUM(PlayerComm_aff)				AS PlayerComm_aff
		,SUM(PlayerCommBase)				AS PlayerCommBase
		,SUM(TotalWinlost) 					AS MemberWinLoss
		,SUM(TotalWinlost_Aff) 				AS MemberWinLoss_Aff
		,SUM(TotalWinlostBase) 				AS MemberWinLossBase
		----------------------PWin,PShare & NetGmaing----------------------
		,SUM(PWin) 							AS PWin
		,SUM(PWin_aff) 						AS PWin_aff
		,SUM(PWinBase) 						AS PWinBase
		,SUM(PShare) 						AS PShare
		,SUM(PShare_aff) 					AS PShare_aff
		,SUM(PShareBase) 					AS PShareBase
		,SUM(NetGaming) 					AS NetGaming		
		,SUM(NetGaming_aff) 				AS NetGaming_aff
		,SUM(NetGamingBase) 				AS NetGamingBase
	FROM #WinLossPaging rpt
	GROUP BY PlayerCurrency
	ORDER BY PlayerCurrency
	
	----------------------SUMTOTAL-----------------------------------
	SELECT 
		SUM(DepositBase) 					AS DepositBase
		,SUM(WithdrawalBase) 				AS WithdrawalBase
		,SUM(PSPBase) 						AS PSPBase
		,SUM(BonusBase) 					AS BonusBase
		,SUM(AdjustmentBase) 				AS AdjustmentBase
		,SUM(BetCount) 						AS BetCount
		,SUM(TotalTurnoverBase) 			AS TotalTurnoverBase
		,SUM(PlayerCommBase) 				AS PlayerCommBase
		,SUM(TotalWinlostBase) 				AS MemberWinLossBase
		----------------------PWin&PShare----------------------------
		,SUM(PShareBase) 					AS PShareBase
		,SUM(PWinBase) 						AS PWinBase
		,SUM(NetGamingBase) 				AS NetGamingBase
	FROM #WinLossPaging rpt
	
	DROP TABLE #WinLossPaging
	
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_MemberWinLossReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_MemberWinLossReport] TO [vnteam] AS [dbo]

