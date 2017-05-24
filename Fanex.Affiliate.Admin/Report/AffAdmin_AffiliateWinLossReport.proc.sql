USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateWinLossReport] 
	@LicenseeID			INT
	,@UserId 			INT				= 0
	,@AffName 			NVARCHAR(100) 	= NULL
	,@AffTypes 			VARCHAR(100)	= NULL
	,@CommGroups 		VARCHAR(1000) 	= NULL
	,@PreferLanguages 	VARCHAR(1000) 	= NULL
	,@Currencies 		VARCHAR(100) 	= NULL
	,@GroupBy 			TINYINT 		= 1
	,@FromDate 			SMALLDATETIME 	= NULL
	,@ToDate 			SMALLDATETIME 	= NULL
	,@DrawFilter 		TINYINT 		= 0
	,@BaseCurrency 		TINYINT 		= 0
	,@SortBy 			TINYINT 		= 0
	,@ExcludeTest 		BIT 			= 1
	,@IsITAdmin 		BIT 			= 0
	,@PageCurrent 		INT 			= 1
	,@PageSize 			INT 			= 25
	,@ProductIds 		VARCHAR(100) 	= NULL
	,@NRows 			INT 			= 0 OUTPUT
	,@Error 			INT 			= 0 OUTPUT
	,@Error_Msg 		NVARCHAR(100) 	= '' OUTPUT
AS

/*    
	Task: Affiliate Win Loss by Product Report - Company View     
	DB: DBAFF.Affiliate_Athena000
	Original: [AffAdmin_AffiliateWinLossReport]

	Revisions:      
		- 20140821@Bobby: Add new Virtual Sport product & PlayerComm
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
                
	Param's Explanation: 
		• @UserId: Admin user id
		• @AffName: Affiliate username
		• @AffTypes: List affilaite type
		• @CommGroups: List Commission group
		• @PreferLanguages: list preference language
		• @Currencies: List currencies
		• @GroupBy:	0 - Affiliate, 1 - Affiliate & Month
		• @FromDate: From date
		• @ToDate: To date
		• @DrawFilter: Bet Count & Turnover filter 
			- 0: "Normal" Betcount and turnover are included
			- 1: "No Draw" The Betcount will be exluded Draw tickets. The turnover will exclude draw & half draw tickets.
			- 2: "No Draw For Turnover Only" The turnover will be excluded draw & half draw tickets.
		• @BaseCurrency: The current exchange rate will be used if we wanna convert the affiliate's currency to system currency
			- 0: Original
			- 1: Convert to System Currency.
			- Note: The exchange rate value will be the exchange rate of current date when we convert the commission value into System Currency.
		• @SortBy: Dropdown list Sort By
			- 0: ActivePlayer
			- 1: AffID
			- 2: BetCount
			- 3: PlayerComm
			- 4: DepositBase
			- 5: WinlostDate
			- 6: TurnoverBase
			- 7: WinlossBase
			- 8: WithdrawalBase
			- Note: Order by field must be converted to system exchange rate.
		• @ExcludeTest: not include test accounts if true.
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	DECLARE @PlaytechCasino	INT

	DECLARE @ProductFilter 	TABLE ( ProductId	INT, ProductName VARCHAR(100) )
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
	CREATE TABLE #AffWinLossRpt	( AffID 					INT
								,WinlostDate 				SMALLDATETIME
								,GroupID 					INT
								,MemberDeposit 				MONEY
								,MemberDeposit_aff 			MONEY
								,MemberWithdrawal 			MONEY
								,MemberWithdrawal_aff 		MONEY
								,MemberPSP 					MONEY
								,MemberPSP_aff 				MONEY
								,MemberBonus 				MONEY
								,MemberBonus_aff 			MONEY
								,MemberAdjustment 			MONEY
								,MemberAdjustment_aff 		MONEY
								,MemberBetCount 			INT
								,ActivePlayer 				INT
								,MemberTurnover 			MONEY
								,MemberTurnover_aff 		MONEY
								,PlayerComm 				MONEY
								,PlayerComm_aff 			MONEY
								,MemberWinlost	 			MONEY
								,MemberWinlost_aff 			MONEY
								,PWin 						MONEY
								,PWin_aff 					MONEY
								,PShare 					MONEY
								,PShare_aff 				MONEY
								,NetGaming					MONEY
								,NetGaming_aff				MONEY
							)

	-- Assign date value
	SET @ToDate					= dbo.Aff_GetLastDayOfMonth(@ToDate)

	-- Get productid
	SELECT @PlaytechCasino		= p.ProductID 
	FROM dbo.Product p WITH(NOLOCK)
	WHERE p.ProductName = 'Playtech Casino'

	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId, ProductName)
		SELECT CONVERT(INT, t.Val), p.ProductName
		FROM [dbo].[strSplit_key](@ProductIds, ',') t
			INNER JOIN dbo.Product p WITH (NOLOCK) ON CONVERT(INT, t.Val) = p.ProductId
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId, ProductName)
		SELECT p.ProductId, p.ProductName
		FROM dbo.Product p WITH (NOLOCK)
	END
	
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
	FROM [dbo].[AffAdmin_AffiliateListForReport](@LicenseeID ,@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

	IF( NOT EXISTS(SELECT TOP 1 1 FROM @AffUserRpt))
	BEGIN
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not avaiable affiliate user.'
		RETURN;
	END
	
	-- collect Affiliate WL data
	INSERT INTO #AffWinLossRpt
	SELECT ac.AffID
		,CASE 
				WHEN @GroupBy = 1 THEN t.MonthDate
				ELSE 0 
			END 								AS WinlostDate
		,CASE 
				WHEN @GroupBy = 1 THEN t.GroupID 
				ELSE 0 
			END 								AS GroupID
		----------------------SUMDATA---------------------------------
		,SUM(ISNULL(ac.MemDeposit, 0))			AS MemberDeposit
		,SUM(ISNULL(ac.MemDeposit_aff, 0))		AS MemberDeposit_aff
		,SUM(ISNULL(ac.MemWithdrawal, 0))		AS MemberWithdrawal
		,SUM(ISNULL(ac.MemWithdrawal_aff, 0))	AS MemberWithdrawal_aff
		,SUM(ISNULL(ac.MemPSP, 0))				AS MemberPSP
		,SUM(ISNULL(ac.MemPSP_aff, 0))			AS MemberPSP_aff
		,SUM(ISNULL(ac.MemBonus, 0))			AS MemberBonus
		,SUM(ISNULL(ac.MemBonus_aff, 0))		AS MemberBonus_aff
		,SUM(ISNULL(ac.MemAdjustment, 0))		AS MemberAdjustment
		,SUM(ISNULL(ac.MemAdjustment_aff, 0)) 	AS MemberAdjustment_aff
		,SUM(CASE 
				WHEN @DrawFilter = 1 THEN ISNULL(ac.MemBetCountNoDraw, 0)
				ELSE ISNULL(ac.MemBetCount, 0)
			END)								AS MemberBetCount
		,0										AS ActivePlayer
		,SUM(CASE 
			WHEN @DrawFilter = 0 THEN ISNULL(ac.MemTurnover, 0)
			ELSE ISNULL(ac.MemTurnoverNoDraw, 0)
			END)								AS MemberTurnover
		,SUM(CASE 
				WHEN @DrawFilter = 0 THEN ISNULL(ac.MemTurnover_aff, 0)
				ELSE ISNULL(ac.MemTurnoverNoDraw_aff, 0)
			END)								AS MemberTurnover_aff
		,SUM(ISNULL(ac.MemPlayerComm, 0))		AS PlayerComm
		,SUM(ISNULL(ac.MemPlayerComm_aff, 0))	AS PlayerComm_aff
		,- SUM(ISNULL(ac.MemWinlost, 0))		AS MemberWinlost
		,- SUM(ISNULL(ac.MemWinlost_aff, 0))	AS MemberWinlost_aff
		------------------PWin&PShare--------------------------------
		,SUM(ISNULL(ac.PWin, 0))				AS PWin
		,SUM(ISNULL(ac.PWin_Aff,0))				AS PWin_aff
		,SUM(ISNULL(ac.PShare,0))				AS PShare
		,SUM(ISNULL(ac.PShare_Aff,0))			AS PShare_aff
		,SUM(CASE 
			WHEN ac.ProductId = @PlaytechCasino THEN (- ac.MemWinlost -  ac.PShare) 
			ELSE 0 
		END)										AS NetGaming
		,SUM(CASE 
			WHEN ac.ProductId = @PlaytechCasino THEN (- ac.MemWinlost_aff -  ac.PShare_aff) 
			ELSE 0 
		END)										AS NetGaming_aff
	FROM dbo.AffDailySummary ac
		INNER JOIN @AffUserRpt AS t
		ON ac.AffId = t.AffId 
			AND DATEDIFF(M, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN @ProductFilter p
		ON ac.ProductId = p.ProductId
	WHERE ac.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY ac.AffID
		,CASE 
				WHEN @GroupBy = 1 THEN t.MonthDate
				ELSE 0 
			END
		,CASE 
				WHEN @GroupBy = 1 THEN t.GroupID 
				ELSE 0 
			END

	IF(NOT EXISTS(SELECT TOP 1 1 FROM #AffWinLossRpt))
	BEGIN 
		SELECT @Error 	= 101
			,@Error_Msg = 'There is not avaiable data.'
		RETURN
	END

	---update active players
	;WITH statsActivePlayer AS (
		SELECT md.AffID
			,CASE WHEN @GroupBy = 1 THEN t.MonthDate ELSE 0 END AS WinlostDate
			,COUNT(DISTINCT md.UserName) AS ActivePlayer
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @AffUserRpt AS t ON md.AffId = t.AffId AND DATEDIFF(M, md.WinlostDate, t.MonthDate) = 0
			INNER JOIN @ProductFilter p ON md.ProductId = p.ProductId
		WHERE md.Winlostdate BETWEEN @FromDate AND @ToDate
			AND md.Turnover > 0
		GROUP BY md.AffID
			,CASE WHEN @GroupBy = 1 THEN t.MonthDate ELSE 0 END
	)
	UPDATE rpt
	SET rpt.ActivePlayer = ISNULL(ap.ActivePlayer, 0)
	FROM #AffWinLossRpt rpt
	LEFT JOIN statsActivePlayer ap 
		ON rpt.AffID 			= ap.AffID 
			AND rpt.WinlostDate = ap.WinlostDate
			
	;WITH AffInfoTmp AS (
		SELECT ai.AffID
			,CASE WHEN @GroupBy = 1 THEN ai.MonthDate ELSE 0 END AS MonthDate 
			,ai.UserName
			,ai.AffType
			,ai.[LANGUAGE]
			,ai.ExchangeID AS CurrencyId
			,ai.Currency
			,CASE WHEN @GroupBy = 1 THEN ai.GroupID ELSE 0 END AS GroupID 
			,CASE WHEN @GroupBy = 1 THEN ai.GroupName ELSE '-' END AS GroupName 
			,CASE WHEN @GroupBy = 1 THEN ai.[STATUS] ELSE '-' END AS [STATUS]
		FROM @AffUserRpt AS ai
		GROUP BY ai.AffID
			,CASE WHEN @GroupBy = 1 THEN ai.MonthDate ELSE 0 END
			,ai.UserName
			,ai.AffType
			,ai.[LANGUAGE]
			,ai.ExchangeID
			,ai.Currency
			,CASE WHEN @GroupBy = 1 THEN ai.GroupID ELSE 0 END
			,CASE WHEN @GroupBy = 1 THEN ai.GroupName ELSE '-' END
			,CASE WHEN @GroupBy = 1 THEN ai.[STATUS] ELSE '-' END
	)
	SELECT rpt.AffID
		,rpt.WinlostDate 
		,ai.UserName
		,ai.AffType
		,ai.[LANGUAGE]
		,ai.GroupID
		,ai.GroupName
		,ai.[STATUS]
		,ai.CurrencyId
		,ai.Currency
		----------------------SUMDATA---------------------------------
		,rpt.MemberDeposit_aff							AS Deposit
		,rpt.MemberDeposit								AS DepositBase
		,rpt.MemberWithdrawal_aff						AS Withdrawal
		,rpt.MemberWithdrawal							AS WithdrawalBase
		,rpt.MemberPSP_aff								AS PSP
		,rpt.MemberPSP									AS PSPBase
		,rpt.MemberBonus_aff							AS Bonus
		,rpt.MemberBonus								AS BonusBase
		,rpt.MemberAdjustment_aff 						AS Adjustment
		,rpt.MemberAdjustment							AS AdjustmentBase
		,rpt.MemberBetCount 							AS BetCount
		,rpt.ActivePlayer 								AS ActivePlayers
		,rpt.MemberTurnover_aff 						AS Turnover
		,rpt.MemberTurnover 							AS TurnoverBase
		,rpt.PlayerComm_aff								AS PlayerComm
		,rpt.PlayerComm									AS PlayerCommBase
		,rpt.MemberWinlost_aff							AS Winloss
		,rpt.MemberWinlost	 							AS WinlossBase
		----------------------PWin&PShare----------------------------
		,rpt.PWin_aff 									AS PWin
		,rpt.PWin	 									AS PWinBase
		,rpt.PShare_aff									AS PShare
		,rpt.PShare 									AS PShareBase
		,rpt.NetGaming_aff								AS NetGaming
		,rpt.NetGaming 									AS NetGamingBase
			----------------------PAGING---------------------------------
		,ROW_NUMBER() OVER ( 
					ORDER BY (CASE 
						WHEN @SortBy = 0 THEN rpt.ActivePlayer
						WHEN @SortBy = 2 THEN rpt.MemberBetCount
						WHEN @SortBy = 3 THEN CASE WHEN @BaseCurrency = 1 THEN rpt.PlayerComm 		ELSE rpt.PlayerComm_Aff 		END
						WHEN @SortBy = 4 THEN CASE WHEN @BaseCurrency = 1 THEN rpt.MemberDeposit 	ELSE rpt.MemberDeposit_Aff 		END
						WHEN @SortBy = 6 THEN CASE WHEN @BaseCurrency = 1 THEN rpt.MemberTurnover 	ELSE rpt.MemberTurnover_Aff 	END
						WHEN @SortBy = 7 THEN CASE WHEN @BaseCurrency = 1 THEN rpt.MemberWinlost  	ELSE rpt.MemberWinlost_Aff 		END
						WHEN @SortBy = 8 THEN CASE WHEN @BaseCurrency = 1 THEN rpt.MemberWithdrawal	ELSE rpt.MemberWithdrawal_Aff 	END
					END) DESC
					, CASE WHEN @SortBy = 1 THEN ai.UserName END ASC 
					, CASE WHEN @SortBy = 5 THEN rpt.WinlostDate END ASC 
					, CASE WHEN @SortBy <> 1 THEN ai.UserName END ASC 
					, CASE WHEN @SortBy <> 5 THEN rpt.WinlostDate END ASC 
		) AS RowIDX
	INTO #rptWinLossPaging
	FROM #AffWinLossRpt rpt
		INNER JOIN AffInfoTmp AS ai ON rpt.AffId = ai.AffId AND rpt.WinlostDate = ai.MonthDate
	
	--select PageTotal
	SELECT @NRows = COUNT(1)
	FROM #rptWinLossPaging rpt
	
	--select data/PageSize
	SELECT
		rpt.RowIDX 
		,rpt.AffID
		,rpt.Username
		,rpt.WinlostDate
		,rpt.AffType
		,rpt.[LANGUAGE]
		,rpt.GroupId
		,rpt.GroupName
		,rpt.[STATUS]
		,rpt.CurrencyId
		,rpt.Currency
		----------------------SUMDATA---------------------------------
		,rpt.Deposit
		,rpt.DepositBase
		,rpt.Withdrawal
		,rpt.WithdrawalBase
		,rpt.PSP
		,rpt.PSPBase
		,rpt.Bonus
		,rpt.BonusBase
		,rpt.Adjustment
		,rpt.AdjustmentBase
		,rpt.BetCount
		,rpt.ActivePlayers
		,rpt.Turnover
		,rpt.TurnoverBase
		,rpt.PlayerComm
		,rpt.PlayerCommBase
		,rpt.Winloss		AS AffiliateWinLoss
		,rpt.WinlossBase	AS AffiliateWinLossBase
		----------------------PWin&PShare----------------------------
		,rpt.PShare
		,rpt.PShareBase
		,rpt.PWin
		,rpt.PWinBase
		,rpt.NetGaming
		,rpt.NetGamingBase
	FROM #rptWinLossPaging rpt
	WHERE rpt.RowIDX BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
	ORDER BY rpt.RowIDX ASC
	
	--Sum total/aff currency
	SELECT 
		rpt.CurrencyId
		,rpt.Currency
		----------------------SUMDATA---------------------------------
		,SUM(rpt.Deposit) 			AS Deposit
		,SUM(rpt.DepositBase) 		AS DepositBase
		,SUM(rpt.Withdrawal) 		AS Withdrawal
		,SUM(rpt.WithdrawalBase) 	AS WithdrawalBase
		,SUM(rpt.PSP) 				AS PSP
		,SUM(rpt.PSPBase) 			AS PSPBase
		,SUM(rpt.Bonus) 			AS Bonus
		,SUM(rpt.BonusBase) 		AS BonusBase
		,SUM(rpt.Adjustment) 		AS Adjustment
		,SUM(rpt.AdjustmentBase) 	AS AdjustmentBase
		,SUM(rpt.BetCount) 			AS BetCount
		,SUM(rpt.ActivePlayers) 	AS ActivePlayers
		,SUM(rpt.Turnover) 			AS Turnover
		,SUM(rpt.TurnoverBase) 		AS TurnoverBase
		,SUM(rpt.PlayerComm) 		AS PlayerComm
		,SUM(rpt.PlayerCommBase) 	AS PlayerCommBase
		,SUM(rpt.Winloss) 			AS AffiliateWinLoss
		,SUM(rpt.WinlossBase) 		AS AffiliateWinLossBase
		----------------------PWin&PShare----------------------------
		,SUM(rpt.PShare) 			AS PShare
		,SUM(rpt.PShareBase) 		AS PShareBase
		,SUM(rpt.PWin) 				AS PWin
		,SUM(rpt.PWinBase) 			AS PWinBase
		,SUM(rpt.NetGaming) 		AS NetGaming
		,SUM(rpt.NetGamingBase) 	AS NetGamingBase
	FROM #rptWinLossPaging rpt
	GROUP BY rpt.CurrencyId
		, rpt.Currency
	ORDER BY rpt.Currency ASC

	----------------------SUMTOTAL---------------------------------
	SELECT 
		SUM(rpt.Deposit) 			AS Deposit
		,SUM(rpt.DepositBase) 		AS DepositBase
		,SUM(rpt.Withdrawal) 		AS Withdrawal
		,SUM(rpt.WithdrawalBase) 	AS WithdrawalBase
		,SUM(rpt.PSP) 				AS PSP
		,SUM(rpt.PSPBase) 			AS PSPBase
		,SUM(rpt.Bonus) 			AS Bonus
		,SUM(rpt.BonusBase) 		AS BonusBase
		,SUM(rpt.Adjustment) 		AS Adjustment
		,SUM(rpt.AdjustmentBase) 	AS AdjustmentBase
		,SUM(rpt.BetCount) 			AS BetCount
		,SUM(rpt.ActivePlayers) 	AS ActivePlayers
		,SUM(rpt.Turnover) 			AS Turnover
		,SUM(rpt.TurnoverBase) 		AS TurnoverBase
		,SUM(rpt.PlayerComm) 		AS PlayerComm
		,SUM(rpt.PlayerCommBase) 	AS PlayerCommBase
		,SUM(rpt.Winloss) 			AS AffiliateWinLoss
		,SUM(rpt.WinlossBase) 		AS AffiliateWinLossBase
		----------------------PWin&PShare----------------------------
		,SUM(rpt.PShare) 			AS PShare
		,SUM(rpt.PShareBase) 		AS PShareBase
		,SUM(rpt.PWin) 				AS PWin
		,SUM(rpt.PWinBase) 			AS PWinBase
		,SUM(rpt.NetGaming) 		AS NetGaming
		,SUM(rpt.NetGamingBase) 	AS NetGamingBase
	FROM #rptWinLossPaging rpt

	DROP TABLE #rptWinLossPaging;
	DROP TABLE #AffWinLossRpt
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateWinLossReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateWinLossReport] TO [vnteam] AS [dbo]
GO