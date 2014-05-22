ALTER PROCEDURE [dbo].[AffAdmin_CompanyWinlossReport] 
	@UserId INT = 0
	,@AffName NVARCHAR(100) = NULL
	,@AffTypes VARCHAR(100) = NULL
	,@CommGroups VARCHAR(1000) = NULL
	,@PreferLanguages VARCHAR(1000) = NULL
	,@PlayerCurrencies VARCHAR(100) = NULL
	,@GroupBy TINYINT = 0
	,@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@DrawFilter TINYINT = 0
	,@BaseCurrency TINYINT = 0
	,@ExcludeTest BIT = 1
	,@IsITAdmin BIT = 0
	,@PageCurrent INT = 1
	,@PageSize INT = 25
	,@ProductIds VARCHAR(100) = NULL
	,@NRows INT = 0 OUTPUT
	,@duration INT = 0 OUTPUT
	
AS
/*    
	Task : Company winloss report      
	DB:    
	Original:[[AffAdmin_CompanyWinlossReport]]      
	Revisions:
		- 20140326@Bobby: Apply paging
		- 20140513@Bobby: Add Playtech Casio product    
                
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

	DECLARE @startRun DATETIME
		,@endRun DATETIME

	SET @startRun = GETDATE()

	--Reset todate to ending of date
	SELECT @ToDate = dbo.Aff_GetEndDate(@ToDate)

	-- Get productid
	DECLARE @SportsbookId INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT
		,@PlaytechCasino INT

	DECLARE  @AffUser TABLE (
		AffId INT
		,Username NVARCHAR(30)
		,AffType VARCHAR(50)
		,LANGUAGE NVARCHAR(255)
		,ExchangeId INT
		,Currency VARCHAR(5)
		,STATUS VARCHAR(50)
		,MonthDate DATETIME
		,GroupId INT
		,GroupName NVARCHAR(100)
	)

	SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		,@PlaytechCasino = dbo.[Aff_GetProductID]('Playtech Casino')

	DECLARE @ProductFilter AS TABLE (ProductId INT)
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

	SELECT ex.ExchangeId AS CurrencyId
		,ex.Code AS Currency
	INTO #PlayerCurrencies
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN Exchange ex WITH (NOLOCK)
		ON tmp.Val = ex.ExchangeId
	
	INSERT INTO @AffUser (
		AffId
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,STATUS
		,MonthDate
		,GroupId
		,GroupName
	)
	SELECT AffId
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,STATUS
		,MonthDate
		,GroupId
		,GroupName
	FROM [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t

	IF (@GroupBy = 0) --Group by Date
	BEGIN
		WITH rptMemWinlost AS 
		(
			SELECT ad.Winlostdate
				,pc.Currency
				,pc.CurrencyId
				,ad.SysExRate AS ExRate
				,ad.AffExRate
				,SUM(ISNULL(ad.MemDeposit, 0)) AS Deposit
				,SUM(ISNULL(ad.MemWithdrawal, 0)) AS Withdrawal
				,SUM(ISNULL(ad.MemBonus, 0)) AS Bonus
				,SUM(ISNULL(ad.MemAdjustment, 0)) AS Adjustment
				,SUM(ISNULL(ad.MemPSP, 0)) AS PSP
				,ISNULL(m.ActivePlayer, 0) AS ActivePlayer
				,CAST(SUM(CASE 
					WHEN @DrawFilter = 1 THEN ISNULL(ad.MemBetCountNoDraw, 0)
					ELSE ISNULL(ad.MemBetCount, 0)
					END) AS INT) AS BetCount
				-- TotalTurnover & Product Turnover
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END) AS TotalTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS SportsbookTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS NumberGameTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS LiveCasinoTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS RNGCasinoTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @PlaytechCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS PlaytechCasinoTurnover
				
				-- TotalWinlost & Product Winlost
				,SUM(ISNULL(ad.MemWinlost, 0)) AS TotalWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS SportsbookWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS NumberGameWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS LiveCasinoWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS RNGCasinoWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @PlaytechCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS PlaytechCasinoWinlost
			FROM AffDaily ad WITH (NOLOCK)
				INNER JOIN @ProductFilter p
				ON ad.ProductId = p.ProductId
				INNER JOIN #PlayerCurrencies AS pc
				ON ad.MemCurrency = pc.CurrencyId
				INNER JOIN @AffUser AS t
				ON ad.AffId = t.AffId
					AND DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
				LEFT JOIN (
					SELECT Winlostdate
						,COUNT(DISTINCT m.Username) AS ActivePlayer
					FROM MemberDaily m WITH (NOLOCK)
						INNER JOIN @AffUser AS t
						ON m.AffId = t.AffId
							AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
						INNER JOIN @ProductFilter p
						ON m.ProductId = p.ProductId
					WHERE Winlostdate BETWEEN @FromDate AND @ToDate
						AND Turnover > 0
					GROUP BY Winlostdate
				) AS m
				ON DATEDIFF(d, ad.Winlostdate, m.WinlostDate) = 0
			WHERE ad.Winlostdate BETWEEN @FromDate AND @ToDate
			GROUP BY ad.Winlostdate
				,pc.Currency
				,pc.CurrencyId
				,ad.SysExRate
				,ad.AffExRate
				,m.ActivePlayer
			HAVING SUM(ad.MemDeposit) > 0
				OR SUM(ad.MemWinlost) > 0
				OR SUM(ad.MemBonus) > 0
				OR SUM(ad.MemAdjustment) > 0
				OR SUM(ad.MemTurnover) > 0
		)
		--select rpt data
		SELECT Winlostdate
			,Currency
			,CurrencyId
			,ExRate
			,CASE @BaseCurrency
				WHEN 2 THEN AffExRate
				ELSE 1
			END AffExRate
			,ActivePlayer
			,BetCount
			-- member currency
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,PSP
			,TotalTurnover
			,TotalWinlost
			,SportsbookTurnover
			,NumberGameTurnover
			,LiveCasinoTurnover
			,RNGCasinoTurnover
			,PlaytechCasinoTurnover
			,SportsbookWinlost
			,NumberGameWinlost
			,LiveCasinoWinlost
			,RNGCasinoWinlost
			,PlaytechCasinoWinlost
			-- system currency
			,ISNULL(rpt.Deposit, 0) * rpt.ExRate AS DepositBase
			,ISNULL(rpt.Withdrawal, 0) * rpt.ExRate AS WithdrawalBase
			,ISNULL(rpt.Bonus, 0) * rpt.ExRate AS BonusBase
			,ISNULL(rpt.Adjustment, 0) * rpt.ExRate AS AdjustmentBase
			,ISNULL(rpt.PSP, 0) * rpt.ExRate AS PSPBase
			,ISNULL(rpt.TotalTurnover, 0) * rpt.ExRate AS TotalTurnoverBase
			,ISNULL(rpt.TotalWinlost, 0) * rpt.ExRate AS TotalWinlostBase
			,ISNULL(rpt.SportsbookTurnover, 0) * rpt.ExRate AS SportsbookTurnoverBase
			,ISNULL(rpt.NumberGameTurnover, 0) * rpt.ExRate AS NumberGameTurnoverBase
			,ISNULL(rpt.LiveCasinoTurnover, 0) * rpt.ExRate AS LiveCasinoTurnoverBase
			,ISNULL(rpt.RNGCasinoTurnover, 0) * rpt.ExRate AS RNGCasinoTurnoverBase
			,ISNULL(rpt.PlaytechCasinoTurnover, 0) * rpt.ExRate AS PlaytechCasinoTurnoverBase
			,ISNULL(rpt.SportsbookWinlost, 0) * rpt.ExRate AS SportsbookWinlostBase
			,ISNULL(rpt.NumberGameWinlost, 0) * rpt.ExRate AS NumberGameWinlostBase
			,ISNULL(rpt.LiveCasinoWinlost, 0) * rpt.ExRate AS LiveCasinoWinlostBase
			,ISNULL(rpt.RNGCasinoWinlost, 0) * rpt.ExRate AS RNGCasinoWinlostBase
			,ISNULL(rpt.PlaytechCasinoWinlost, 0) * rpt.ExRate AS PlaytechCasinoWinlostBase
			-- aff currency
			,ISNULL(rpt.Deposit, 0) * rpt.AffExRate AS Deposit_Aff
			,ISNULL(rpt.Withdrawal, 0) * rpt.AffExRate AS Withdrawal_Aff
			,ISNULL(rpt.Bonus, 0) * rpt.ExRate AS Bonus_Aff
			,ISNULL(rpt.Adjustment, 0) * rpt.AffExRate AS Adjustment_Aff
			,ISNULL(rpt.PSP, 0) * rpt.AffExRate AS PSP_Aff
			,ISNULL(rpt.TotalTurnover, 0) * rpt.AffExRate AS TotalTurnover_Aff
			,ISNULL(rpt.TotalWinlost, 0) * rpt.AffExRate AS TotalWinlost_Aff
			,ISNULL(rpt.SportsbookTurnover, 0) * rpt.AffExRate AS SportsbookTurnover_Aff
			,ISNULL(rpt.NumberGameTurnover, 0) * rpt.AffExRate AS NumberGameTurnover_Aff
			,ISNULL(rpt.LiveCasinoTurnover, 0) * rpt.AffExRate AS LiveCasinoTurnover_Aff
			,ISNULL(rpt.RNGCasinoTurnover, 0) * rpt.AffExRate AS RNGCasinoTurnover_Aff
			,ISNULL(rpt.PlaytechCasinoTurnover, 0) * rpt.AffExRate AS PlaytechCasinoTurnover_Aff
			,ISNULL(rpt.SportsbookWinlost, 0) * rpt.AffExRate AS SportsbookWinlost_Aff
			,ISNULL(rpt.NumberGameWinlost, 0) * rpt.AffExRate AS NumberGameWinlost_Aff
			,ISNULL(rpt.LiveCasinoWinlost, 0) * rpt.AffExRate AS LiveCasinoWinlost_Aff
			,ISNULL(rpt.RNGCasinoWinlost, 0) * rpt.AffExRate AS RNGCasinoWinlost_Aff
			,ISNULL(rpt.PlaytechCasinoWinlost, 0) * rpt.AffExRate AS PlaytechCasinoWinlost_Aff
			,ROW_NUMBER() OVER (
				ORDER BY rpt.Winlostdate
			) AS RowNum
		INTO #rptWinlossDate
		FROM rptMemWinlost rpt
		
		SELECT @NRows = count(1)
		FROM #rptWinlossDate rpt
		
		SELECT rpt.* 
		FROM #rptWinlossDate rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
		
		--select sum data by MemberCurrency
		SELECT Currency
			,SUM(ActivePlayer) ActivePlayer
			,SUM(BetCount) BetCount
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(PlaytechCasinoTurnover) PlaytechCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
			,SUM(PlaytechCasinoWinlost) PlaytechCasinoWinlost
			,SUM(TotalWinlost) TotalWinlost

			,SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(PlaytechCasinoTurnoverBase) PlaytechCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
			,SUM(PlaytechCasinoWinlostBase) PlaytechCasinoWinlostBase
			,SUM(TotalWinlostBase) TotalWinlostBase

			,SUM(Deposit_Aff) Deposit_Aff
			,SUM(Withdrawal_Aff) Withdrawal_Aff
			,SUM(Bonus_Aff) Bonus_Aff
			,SUM(Adjustment_Aff) Adjustment_Aff
			,SUM(PSP_Aff) PSP_Aff
			,SUM(SportsBookTurnover_Aff) SportsBookTurnover_Aff
			,SUM(NumberGameTurnover_Aff) NumberGameTurnover_Aff
			,SUM(LiveCasinoTurnover_Aff) LiveCasinoTurnover_Aff
			,SUM(RNGCasinoTurnover_Aff) RNGCasinoTurnover_Aff
			,SUM(PlaytechCasinoTurnover_Aff) PlaytechCasinoTurnover_Aff
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(PlaytechCasinoWinlost_Aff) PlaytechCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossDate
		GROUP BY Currency

		--select sum data by SysCurrency
		SELECT SUM(ActivePlayer) ActivePlayer
			,SUM(BetCount) BetCount
			,SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(PlaytechCasinoTurnoverBase) PlaytechCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
			,SUM(PlaytechCasinoWinlostBase) PlaytechCasinoWinlostBase
			,SUM(TotalWinlostBase) TotalWinlostBase
		FROM #rptWinlossDate


		DROP TABLE #rptWinlossDate
	END
	ELSE
	BEGIN --By Month
		SELECT tmp.WinlostDate
			,tmp.Currency
			,tmp.CurrencyId
			,CAST(1 AS FLOAT) AS ExRate
			-- member currency
			,SUM(MemDeposit) AS Deposit
			,SUM(MemWithdrawal) AS Withdrawal
			,SUM(MemBonus) AS Bonus
			,SUM(MemAdjustment) AS Adjustment
			,SUM(MemPSP) AS PSP
			,SUM(Turnover) AS TotalTurnover
			,SUM(SportsbookTurnover) AS SportsbookTurnover
			,SUM(NumberGameTurnover) AS NumberGameTurnover
			,SUM(LiveCasinoTurnover) AS LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) AS RNGCasinoTurnover
			,SUM(PlaytechCasinoTurnover) AS PlaytechCasinoTurnover
			,CAST(SUM(BetCount) AS INT) AS BetCount
			,CAST(SUM(m.ActivePlayer) AS INT) AS ActivePlayer
			,SUM(MemWinlost) AS TotalWinlost
			,SUM(SportsbookWinlost) AS SportsbookWinlost
			,SUM(NumberGameWinlost) AS NumberGameWinlost
			,SUM(LiveCasinoWinlost) AS LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) AS RNGCasinoWinlost
			,SUM(PlaytechCasinoWinlost) AS PlaytechCasinoWinlost
			-- system currency
			,SUM(MemDepositBase) AS DepositBase
			,SUM(MemWithdrawalBase) AS WithdrawalBase
			,SUM(MemBonusBase) AS BonusBase
			,SUM(MemAdjustmentBase) AS AdjustmentBase
			,SUM(MemPSPBase) AS PSPBase
			,SUM(TurnoverBase) AS TotalTurnoverBase
			,SUM(SportsbookTurnoverBase) AS SportsbookTurnoverBase
			,SUM(NumberGameTurnoverBase) AS NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) AS LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) AS RNGCasinoTurnoverBase
			,SUM(PlaytechCasinoTurnoverBase) AS PlaytechCasinoTurnoverBase
			,SUM(MemWinlostBase) AS TotalWinlostBase
			,SUM(SportsbookWinlostBase) AS SportsbookWinlostBase
			,SUM(NumberGameWinlostBase) AS NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) AS LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) AS RNGCasinoWinlostBase
			,SUM(PlaytechCasinoWinlostBase) AS PlaytechCasinoWinlostBase
			-- aff currency
			,SUM(MemDeposit_Aff) AS Deposit_Aff
			,SUM(MemWithdrawal_Aff) AS Withdrawal_Aff
			,SUM(MemBonus_Aff) AS Bonus_Aff
			,SUM(MemAdjustment_Aff) AS Adjustment_Aff
			,SUM(MemPSP_Aff) AS PSP_Aff
			,SUM(Turnover_Aff) AS TotalTurnover_Aff
			,SUM(SportsbookTurnover_Aff) AS SportsbookTurnover_Aff
			,SUM(NumberGameTurnover_Aff) AS NumberGameTurnover_Aff
			,SUM(LiveCasinoTurnover_Aff) AS LiveCasinoTurnover_Aff
			,SUM(RNGCasinoTurnover_Aff) AS RNGCasinoTurnover_Aff
			,SUM(PlaytechCasinoTurnover_Aff) AS PlaytechCasinoTurnover_Aff
			,SUM(MemWinlost_Aff) AS TotalWinlost_Aff
			,SUM(SportsbookWinlost_Aff) AS SportsbookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) AS NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) AS LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) AS RNGCasinoWinlost_Aff
			,SUM(PlaytechCasinoWinlost_Aff) AS PlaytechCasinoWinlost_Aff
			,ROW_NUMBER() OVER (
				ORDER BY tmp.WinlostDate
				) AS RowNum
		INTO #rptWinlossMonth
		FROM (
			SELECT DATEADD(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
				,pc.Currency
				,pc.CurrencyId
				,SUM(ISNULL(ad.MemDeposit, 0)) AS MemDeposit
				,SUM(ISNULL(ad.MemWithdrawal, 0)) AS MemWithdrawal
				,SUM(ISNULL(ad.MemBonus, 0)) AS MemBonus
				,SUM(ISNULL(ad.MemAdjustment, 0)) AS MemAdjustment
				,SUM(ISNULL(ad.MemPSP, 0)) AS MemPSP
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END) AS Turnover
				,SUM(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS SportsbookTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS NumberGameTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS LiveCasinoTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS RNGCasinoTurnover
				,SUM(CASE 
						WHEN ad.ProductID = @PlaytechCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS PlaytechCasinoTurnover
				,SUM(CASE 
						WHEN @DrawFilter = 1 THEN ISNULL(ad.MemBetCountNoDraw, 0)
						ELSE ISNULL(ad.MemBetCount, 0)
						END) AS BetCount
				,SUM(ISNULL(ad.MemWinlost, 0)) AS MemWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS SportsbookWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS NumberGameWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS LiveCasinoWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS RNGCasinoWinlost
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @PlaytechCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS PlaytechCasinoWinlost
				
				--Convert to System ex.Rate
				,SUM(ISNULL(ad.MemDeposit, 0) * ad.SysExRate) AS MemDepositBase
				,SUM(ISNULL(ad.MemWithdrawal, 0) * ad.SysExRate) AS MemWithdrawalBase
				,SUM(ISNULL(ad.MemBonus, 0) * ad.SysExRate) AS MemBonusBase
				,SUM(ISNULL(ad.MemAdjustment, 0) * ad.SysExRate) AS MemAdjustmentBase
				,SUM(ISNULL(ad.MemPSP, 0) * ad.SysExRate) AS MemPSPBase
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END * ad.SysExRate) AS TurnoverBase
				,SUM(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS SportsbookTurnoverBase
				,SUM(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS NumberGameTurnoverBase
				,SUM(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS LiveCasinoTurnoverBase
				,SUM(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS RNGCasinoTurnoverBase
				,SUM(CASE 
						WHEN ad.ProductID = @PlaytechCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS PlaytechCasinoTurnoverBase
				,SUM(ISNULL(ad.MemWinlost, 0) * ad.SysExRate) AS MemWinlostBase
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS SportsbookWinlostBase
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS NumberGameWinlostBase
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS LiveCasinoWinlostBase
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS RNGCasinoWinlostBase
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @PlaytechCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS PlaytechCasinoWinlostBase
				,- (SUM(ISNULL(ad.MemWinlost, 0) * ad.SysExRate)) AS TotalBase
				,
				--Convert to Affiliate ex.Rate
				SUM(ISNULL(ad.MemDeposit, 0) * ad.AffExRate) AS MemDeposit_Aff
				,SUM(ISNULL(ad.MemWithdrawal, 0) * ad.AffExRate) AS MemWithdrawal_Aff
				,SUM(ISNULL(ad.MemBonus, 0) * ad.AffExRate) AS MemBonus_Aff
				,SUM(ISNULL(ad.MemAdjustment, 0) * ad.AffExRate) AS MemAdjustment_Aff
				,SUM(ISNULL(ad.MemPSP, 0) * ad.AffExRate) AS MemPSP_Aff
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END * ad.AffExRate) AS Turnover_Aff
				,SUM(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS SportsbookTurnover_Aff
				,SUM(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS NumberGameTurnover_Aff
				,SUM(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS LiveCasinoTurnover_Aff
				,SUM(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS RNGCasinoTurnover_Aff
				,SUM(CASE 
						WHEN ad.ProductID = @PlaytechCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS PlaytechCasinoTurnover_Aff
				,SUM(ISNULL(ad.MemWinlost, 0) * ad.AffExRate) AS MemWinlost_Aff
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS SportsbookWinlost_Aff
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS NumberGameWinlost_Aff
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS LiveCasinoWinlost_Aff
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS RNGCasinoWinlost_Aff
				,- (
					SUM(CASE 
							WHEN ad.ProductID = @PlaytechCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS PlaytechCasinoWinlost_Aff
			FROM AffDaily ad WITH (NOLOCK)
				INNER JOIN @ProductFilter p
				ON ad.ProductId = p.ProductId
				INNER JOIN #PlayerCurrencies AS pc
				ON ad.MemCurrency = pc.CurrencyId
				INNER JOIN @AffUser AS t
				ON ad.AffId = t.AffId
					AND DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
			GROUP BY DATEADD(m, datediff(m, 0, Winlostdate), 0)
				,pc.Currency
				,pc.CurrencyId
			) AS tmp
			LEFT JOIN (
			SELECT DATEADD(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
				,COUNT(DISTINCT m.Username) AS ActivePlayer
			FROM MemberDaily m WITH (NOLOCK)
				INNER JOIN @AffUser AS t
				ON m.AffId = t.AffId
					AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
				INNER JOIN @ProductFilter p
				ON m.ProductId = p.ProductId
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
			GROUP BY DATEADD(m, datediff(m, 0, Winlostdate), 0)
			) AS m
			ON DATEDIFF(m, tmp.Winlostdate, m.WinlostDate) = 0
		GROUP BY tmp.Winlostdate
			,tmp.Currency
			,tmp.CurrencyId
		HAVING SUM(tmp.MemDeposit) > 0
			OR SUM(tmp.MemWinlost) > 0
			OR SUM(tmp.MemBonus) > 0
			OR SUM(tmp.MemAdjustment) > 0
			OR SUM(tmp.Turnover) > 0

		SELECT @NRows = count(1)
		FROM #rptWinlossMonth rpt

		--select rpt data
		SELECT *
		FROM #rptWinlossMonth rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)

		--select sum data by MemberCurrency
		SELECT Currency
			,SUM(ActivePlayer) ActivePlayer
			,SUM(BetCount) BetCount
			-- member
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(PlaytechCasinoTurnover) PlaytechCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
			,SUM(PlaytechCasinoWinlost) PlaytechCasinoWinlost
			,SUM(TotalWinlost) TotalWinlost
			-- system
			,SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(PlaytechCasinoTurnoverBase) PlaytechCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
			,SUM(PlaytechCasinoWinlostBase) PlaytechCasinoWinlostBase
			,SUM(TotalWinlostBase) TotalWinlostBase
			-- affiliate
			,SUM(Deposit_Aff) Deposit_Aff
			,SUM(Withdrawal_Aff) Withdrawal_Aff
			,SUM(Bonus_Aff) Bonus_Aff
			,SUM(Adjustment_Aff) Adjustment_Aff
			,SUM(PSP_Aff) PSP_Aff
			,SUM(SportsBookTurnover_Aff) SportsBookTurnover_Aff
			,SUM(NumberGameTurnover_Aff) NumberGameTurnover_Aff
			,SUM(LiveCasinoTurnover_Aff) LiveCasinoTurnover_Aff
			,SUM(RNGCasinoTurnover_Aff) RNGCasinoTurnover_Aff
			,SUM(PlaytechCasinoTurnover_Aff) PlaytechCasinoTurnover_Aff
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(PlaytechCasinoWinlost_Aff) PlayetchCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossMonth
		GROUP BY Currency

		--select sum data by SysCurrency
		SELECT SUM(ActivePlayer) ActivePlayer
			,SUM(BetCount) BetCount
			,SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(PlaytechCasinoTurnoverBase) PlaytechCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
			,SUM(PlaytechCasinoWinlostBase) PlaytechCasinoWinlostBase
			,SUM(TotalWinlostBase) TotalWinlostBase
		FROM #rptWinlossMonth

		DROP TABLE #rptWinlossMonth
	END

	DROP TABLE #PlayerCurrencies

	SET @endRun = getdate()
	SET @duration = datediff(millisecond, @startRun, @endRun)
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CompanyWinlossReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CompanyWinlossReport] TO [vnteam] AS [dbo]
