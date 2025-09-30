/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CompanyWinlossReport] 
	@UserCurrencies 	VARCHAR(MAX)	= ''
	,@AffName 			NVARCHAR(100) 	= NULL
	,@AffTypes 			VARCHAR(100) 	= NULL
	,@CommGroups 		VARCHAR(1000) 	= NULL
	,@PreferLanguages 	VARCHAR(1000) 	= NULL
	,@PlayerCurrencies 	VARCHAR(100) 	= NULL
	,@GroupBy 			TINYINT 		= 0
	,@FromDate 			DATETIME 		= NULL
	,@ToDate 			DATETIME 		= NULL
	,@DrawFilter 		TINYINT 		= 0
	,@BaseCurrency 		TINYINT 		= 0
	,@ExcludeTest 		BIT 			= 1
	,@IsITAdmin 		BIT 			= 0
	,@PageCurrent 		INT 			= 1
	,@PageSize 			INT 			= 25
	,@ProductIds 		VARCHAR(100) 	= NULL
	,@NRows 			INT 			= 0 	OUTPUT
	,@Duration 			INT 			= 0 	OUTPUT
	,@Error 			INT 			= 0 	OUTPUT
	,@Error_Msg 		NVARCHAR(100) 	= '' 	OUTPUT
AS

/*    
	Task : Company winloss report      
	DB: DBAFF.Affiliate_Athena000
	Original: [AffAdmin_CompanyWinlossReport]

	Revisions:
		- 20140326@Bobby: Apply paging
		- 20140513@Bobby: Add Playtech Casio product
		- 20140612@Bobby: Add PShare & PWin columns    
		- 20140827@Bobby: Add Virtual Sport & PlayerComm - apply style-scope
		- 20150126@bobby.nguyen: Check for having report data 
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]
                
	Param's Explanation: 
		• @UserId: Admin user id
		• @AffName: Affiliate username
		• @AffTypes: List affilaite type
		• @CommGroups: List Commission group
		• @PreferLanguages: list preference language
		• @@PlayerCurrencies: List Player currencies
		• @GroupBy: by date or month (0: by date; 1: by month)
		• @FromDate: From date
		• @ToDate: To date
		• @DrawFilter: Bet Count & Turnover filter 
			- 0: "Normal" Betcount and turnover are included
			- 1: "No Draw" The Betcount will be exluded Draw tickets. The turnover will exclude draw & half draw tickets.
			- 2: "No Draw For Turnover Only" The turnover will exclude only draw tickets.
		• @BaseCurrency: The current exchange rate will be used if we wanna convert the affiliate's currency to system currency
			- 0: Original
			- 1: Convert to System Currency.
			- 2: Convert to Affiliate Currency.
		• @ExcludeTest: not include test accounts if true.
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @startRun 		DATETIME
		,@endRun 			DATETIME
		,@CurrentDate		DATETIME
		,@PlaytechCasino 	INT
		,@RptByAff			BIT = 0

	DECLARE  @AffUserRpt 		TABLE
	(
		AffId 				INT
		,Username 			NVARCHAR(30)
		,AffType 			VARCHAR(50)
		,ExchangeId 		INT
		,Currency 			VARCHAR(5)
		,MonthDate 			DATETIME
		,GroupId 			INT
		,GroupName 			NVARCHAR(100)
	)

	DECLARE @ProductFilter TABLE ( ProductId INT )
	DECLARE @MemCurrencies TABLE ( ExchangeId SMALLINT, Currency VARCHAR(10) )

	-- product filtering
	IF (LEN(@ProductIds) > 0)
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT Val
		FROM [dbo].[strSplit](@ProductIds, ',')
	END
	ELSE
	BEGIN
		INSERT INTO @ProductFilter (ProductId)
		SELECT ProductId
		FROM dbo.Product WITH (NOLOCK)
	END
	
	SELECT @CurrentDate 	= GETDATE()
		, @startRun			= @CurrentDate

	--reset fromdate & todate
	SELECT @FromDate		= CASE WHEN @FromDate IS NULL THEN dbo.Aff_GetFirstDayOfMonth(@CurrentDate) 
								ELSE dbo.Aff_GetStartDate(@FromDate) 
							END
		, @ToDate			= CASE WHEN @ToDate IS NULL OR @ToDate > @CurrentDate THEN @CurrentDate 
								ELSE dbo.Aff_GetEndDate(ISNULL(@ToDate, @CurrentDate)) 
								END
	
	-- Get productid
	SELECT @PlaytechCasino	= p.ProductID 
	FROM dbo.Product p WITH(NOLOCK)
	WHERE p.ProductName = 'Playtech Casino'
	
	-- currency fitering
	INSERT INTO @MemCurrencies(ExchangeId, Currency)
	SELECT ex.ExchangeId, ex.Code
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON tmp.Val = ex.ExchangeId
	
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
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserCurrencies, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

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
	
	--- insert into company win loss data
	;WITH CompanyWinLossRpt AS (
		SELECT ad.Winlostdate
			,ad.MemCurrency AS CurrencyID
			,mc.Currency
			,ad.ProductID
			,ad.AffExRate
			,ad.SysExRate
			,ad.MemDeposit
			,ad.MemWithdrawal
			,ad.MemBonus
			,ad.MemAdjustment
			,ad.MemPSP
			,ad.MemWinlost
			,CASE WHEN @DrawFilter = 1 THEN ISNULL(ad.MemBetCountNoDraw, 0)
					ELSE ISNULL(ad.MemBetCount, 0)
				END AS BetCount
			,ad.MemPlayerComm
			,ad.ActivePlayer
			,CASE WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
					ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
				END AS MemTurnover
			,ad.PShare
			,ad.PWin
		FROM [dbo].[AffDaily] ad WITH (NOLOCK)
			INNER JOIN @AffUserRpt ai ON ad.AffID = ai.AffID
				AND DATEDIFF(M, ad.Winlostdate, ai.MonthDate) = 0
			INNER JOIN @ProductFilter p ON ad.ProductID = p.ProductID
			INNER JOIN @MemCurrencies mc ON ad.MemCurrency = mc.ExchangeId
		WHERE ad.Winlostdate BETWEEN @FromDate AND @ToDate
	)
	,rptDatePaging AS (
		SELECT 
			CASE WHEN @GroupBy = 0 THEN rpt.WinlostDate 
					ELSE DATEADD(m, DATEDIFF(m, 0, rpt.WinlostDate), 0) 
				END AS WinlostDate
			,ROW_NUMBER() OVER ( 
				ORDER BY (
					CASE WHEN @GroupBy = 0 THEN rpt.WinlostDate 
						ELSE DATEADD(m, DATEDIFF(m, 0, rpt.WinlostDate), 0)  
					END ) ASC
			) AS RowIDX
		FROM CompanyWinLossRpt rpt
		GROUP BY CASE WHEN @GroupBy = 0 THEN rpt.WinlostDate 
					ELSE DATEADD(m, DATEDIFF(m, 0, rpt.WinlostDate), 0) 
				END
		HAVING SUM(rpt.MemDeposit) 		> 0
			OR SUM(rpt.MemWithdrawal) 	<> 0
			OR SUM(rpt.MemWinlost) 		<> 0
			OR SUM(rpt.MemBonus) 		> 0
			OR SUM(rpt.MemAdjustment)	> 0
			OR SUM(rpt.MemTurnover) 	> 0
	)
	SELECT p.RowIDX
		,p.WinlostDate
		,rpt.CurrencyID
		,rpt.Currency
		,CASE WHEN @GroupBy = 0 THEN rpt.SysExRate ELSE 1 END AS ExRate
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN rpt.AffExRate ELSE 1 END AS AffExRate
		-----------------------------SumData--------------------------------------------------
		,SUM(ISNULL(rpt.MemDeposit, 0)) 	AS Deposit
		,SUM(ISNULL(rpt.MemDeposit, 0) 
			* rpt.AffExRate)				AS Deposit_aff
		,SUM(ISNULL(rpt.MemDeposit, 0) 
			* rpt.SysExRate)				AS DepositBase
		,SUM(ISNULL(rpt.MemWithdrawal, 0)) 	AS Withdrawal
		,SUM(ISNULL(rpt.MemWithdrawal, 0)
			* rpt.AffExRate) 				AS Withdrawal_aff
		,SUM(ISNULL(rpt.MemWithdrawal, 0)
			* rpt.SysExRate) 				AS WithdrawalBase
		,SUM(ISNULL(rpt.MemPSP, 0)) 		AS PSP
		,SUM(ISNULL(rpt.MemPSP, 0)
			* rpt.AffExRate)		 		AS PSP_aff
		,SUM(ISNULL(rpt.MemPSP, 0)
			* rpt.SysExRate)		 		AS PSPBase
		,SUM(ISNULL(rpt.MemBonus, 0)) 		AS Bonus
		,SUM(ISNULL(rpt.MemBonus, 0)
			* rpt.AffExRate) 				AS Bonus_aff
		,SUM(ISNULL(rpt.MemBonus, 0)
			* rpt.SysExRate) 				AS BonusBase
		,SUM(ISNULL(rpt.MemAdjustment, 0)) 	AS Adjustment
		,SUM(ISNULL(rpt.MemAdjustment, 0)
			* rpt.AffExRate) 				AS Adjustment_aff
		,SUM(ISNULL(rpt.MemAdjustment, 0)
			* rpt.SysExRate) 				AS AdjustmentBase
		,SUM(BetCount)						AS BetCount
		,0 									AS ActivePlayer
		,SUM(ISNULL(rpt.MemTurnover, 0))	AS TotalTurnover
		,SUM(ISNULL(rpt.MemTurnover, 0) 
				* rpt.AffExRate)			AS TotalTurnover_aff
		,SUM(ISNULL(rpt.MemTurnover, 0)
				* rpt.SysExRate)			AS TotalTurnoverBase
		,SUM(ISNULL(rpt.MemPlayerComm, 0)) 	AS PlayerComm
		,SUM(ISNULL(rpt.MemPlayerComm, 0)
			* rpt.AffExRate) 				AS PlayerComm_aff
		,SUM(ISNULL(rpt.MemPlayerComm, 0)
			* rpt.SysExRate) 				AS PlayerCommBase
		,- SUM(ISNULL(rpt.MemWinlost, 0)) 	AS TotalWinlost
		,- SUM(ISNULL(rpt.MemWinlost, 0)
			* rpt.AffExRate)			 	AS TotalWinlost_aff
		,- SUM(ISNULL(rpt.MemWinlost, 0)
			* rpt.SysExRate)			 	AS TotalWinlostBase
		-----------------------------PWin,PShare & NetGmaing-------------------------------------
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN ISNULL(rpt.PShare, 0)
				ELSE 0
				END) 						AS PShare
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN (ISNULL(rpt.PShare, 0) * rpt.AffExRate)
				ELSE 0
				END) 						AS PShare_aff
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN (ISNULL(rpt.PShare, 0) * rpt.SysExRate)
				ELSE 0
				END) 						AS PShareBase
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN ISNULL(rpt.PWin, 0)
				ELSE 0
				END) 						AS PWin
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN (ISNULL(rpt.PWin, 0) * rpt.AffExRate)
				ELSE 0
				END) 						AS PWin_aff
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN (ISNULL(rpt.PWin, 0) * rpt.SysExRate)
				ELSE 0
				END) 						AS PWinBase
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN (-ISNULL(rpt.MemWinlost, 0) - ISNULL(rpt.PShare, 0))
				ELSE 0
				END) 						AS NetGaming
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN ((-ISNULL(rpt.MemWinlost, 0) - ISNULL(rpt.PShare, 0)) * rpt.AffExRate)
				ELSE 0
				END) 						AS NetGaming_aff
		,SUM(CASE 
				WHEN rpt.ProductID = @PlaytechCasino THEN ((-ISNULL(rpt.MemWinlost, 0) - ISNULL(rpt.PShare, 0)) * rpt.SysExRate)
				ELSE 0
				END) 						AS NetGamingBase
	INTO #WinLossPaging
	FROM rptDatePaging p
		INNER JOIN CompanyWinLossRpt rpt ON p.WinlostDate = CASE WHEN @GroupBy = 0 THEN rpt.WinlostDate 
							ELSE DATEADD(m, DATEDIFF(m, 0, rpt.WinlostDate), 0)
						END 
	GROUP BY p.RowIDX
		,p.WinlostDate
		,rpt.CurrencyID
		,rpt.Currency
		,CASE WHEN @GroupBy = 0 THEN rpt.SysExRate 
				ELSE 1
			END
		,CASE WHEN @GroupBy = 0 AND @RptByAff = 1 THEN rpt.AffExRate 
				ELSE 1
			END
	ORDER BY p.RowIDX
		,rpt.Currency
	
	--- fetch final result
	SELECT @NRows = COUNT(DISTINCT RowIDX)
	FROM #WinLossPaging rpt;
	
	-- collect active players
	WITH ActivePlayer AS (
		SELECT md.Currency
			,CASE WHEN @GroupBy = 0 THEN md.WinlostDate 
					ELSE DATEADD(m, DATEDIFF(m, 0, md.Winlostdate), 0)  
				END 						AS Winlostdate
			,COUNT(DISTINCT md.Username) 	AS ActivePlayer
		FROM dbo.MemberDaily md WITH (NOLOCK)
			INNER JOIN @AffUserRpt AS t ON md.AffId = t.AffId AND DATEDIFF(m, md.WinlostDate, t.MonthDate) = 0
			INNER JOIN @ProductFilter p ON md.ProductId = p.ProductId
			INNER JOIN @MemCurrencies mc ON md.Currency = mc.ExchangeId
		WHERE md.Winlostdate BETWEEN @FromDate AND @ToDate 
			AND md.Turnover > 0
		GROUP BY md.Currency
			,CASE WHEN @GroupBy = 0 THEN md.WinlostDate 
					ELSE DATEADD(m, DATEDIFF(m, 0, md.Winlostdate), 0)  
				END
	)	
	UPDATE rpt
	SET rpt.ActivePlayer = ISNULL(pl.ActivePlayer, 0)
	FROM #WinLossPaging rpt
		LEFT JOIN ActivePlayer pl
		ON rpt.Winlostdate = pl.Winlostdate
			AND rpt.CurrencyID = pl.Currency
		
	--select rpt data
	SELECT 
		rpt.RowIDX
		,rpt.Winlostdate
		,rpt.CurrencyID
		,rpt.Currency
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
		,rpt.ActivePlayer
		,rpt.TotalTurnover
		,rpt.TotalTurnover_aff
		,rpt.TotalTurnoverBase
		,rpt.PlayerComm
		,rpt.PlayerComm_aff
		,rpt.PlayerCommBase
		,rpt.TotalWinlost		AS CompanyWinLoss
		,rpt.TotalWinlost_Aff	AS CompanyWinLoss_Aff
		,rpt.TotalWinlostBase	AS CompanyWinLossBase
		,rpt.PShare
		,rpt.PShare_aff
		,rpt.PShareBase
		,rpt.PWin
		,rpt.PWin_aff
		,rpt.PWinBase
		,rpt.NetGaming
		,rpt.NetGaming_aff
		,rpt.NetGamingBase
	FROM #WinLossPaging rpt
	WHERE rpt.RowIDX BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
	ORDER BY rpt.RowIDX ASC
		,rpt.Currency 	ASC
	
	--select sum data by MemberCurrency
	SELECT Currency
		-----------------------------SumData----------------------------
		,SUM(ActivePlayer) 					AS ActivePlayer
		,SUM(BetCount) 						AS BetCount
		,SUM(Deposit) 						AS Deposit
		,SUM(Deposit_Aff) 					AS Deposit_Aff
		,SUM(DepositBase) 					AS DepositBase
		,SUM(Withdrawal) 					AS Withdrawal
		,SUM(Withdrawal_Aff) 				AS Withdrawal_Aff
		,SUM(WithdrawalBase) 				AS WithdrawalBase
		,SUM(Bonus) 						AS Bonus
		,SUM(Bonus_Aff) 					AS Bonus_Aff
		,SUM(BonusBase) 					AS BonusBase
		,SUM(Adjustment) 					AS Adjustment
		,SUM(Adjustment_Aff) 				AS Adjustment_Aff
		,SUM(AdjustmentBase) 				AS AdjustmentBase
		,SUM(PSP) 							AS PSP
		,SUM(PSP_Aff) 						AS PSP_Aff
		,SUM(PSPBase) 						AS PSPBase
		,SUM(PlayerComm)					AS PlayerComm
		,SUM(PlayerComm_aff)				AS PlayerComm_aff
		,SUM(PlayerCommBase)				AS PlayerCommBase
		,SUM(TotalTurnover) 				AS TotalTurnover
		,SUM(TotalTurnover_aff)				AS TotalTurnover_aff
		,SUM(TotalTurnoverBase)				AS TotalTurnoverBase
		,SUM(TotalWinlost) 					AS CompanyWinLoss
		,SUM(TotalWinlost_Aff) 				AS CompanyWinLoss_Aff
		,SUM(TotalWinlostBase) 				AS CompanyWinLossBase
		-----------------------------PShare,PWin & NetGaming--------------------
		,SUM(PShare) 						AS PShare
		,SUM(PShare_aff) 					AS PShare_aff
		,SUM(PShareBase) 					AS PShareBase
		,SUM(PWin) 							AS PWin
		,SUM(PWin_aff) 						AS PWin_aff
		,SUM(PWinBase) 						AS PWinBase
		,SUM(NetGaming) 					AS NetGaming
		,SUM(NetGaming_aff) 				AS NetGaming_aff
		,SUM(NetGamingBase) 				AS NetGamingBase
	FROM #WinLossPaging
	GROUP BY Currency 
	ORDER BY Currency ASC

	--select sum data by SysCurrency
	SELECT SUM(ActivePlayer) 				AS ActivePlayer
		,SUM(BetCount) 						AS BetCount
		,SUM(DepositBase) 					AS DepositBase
		,SUM(WithdrawalBase) 				AS WithdrawalBase
		,SUM(BonusBase) 					AS BonusBase
		,SUM(AdjustmentBase) 				AS AdjustmentBase
		,SUM(PSPBase) 						AS PSPBase
		,SUM(PlayerCommBase)				AS PlayerCommBase
		,SUM(TotalTurnoverBase) 			AS TotalTurnoverBase
		,SUM(TotalWinlostBase) 				AS CompanyWinLossBase
		,SUM(PShareBase) 					AS PShareBase
		,SUM(PWinBase) 						AS PWinBase
		,SUM(NetGamingBase) 				AS NetGamingBase			
	FROM #WinLossPaging	
		
	DROP TABLE #WinLossPaging
	
	SELECT @endRun = GETDATE()
		,@Duration = DATEDIFF(millisecond, @startRun, @endRun)
END
GO