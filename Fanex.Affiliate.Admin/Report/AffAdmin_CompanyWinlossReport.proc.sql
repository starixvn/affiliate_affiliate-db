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
	,@NRows INT = 0 OUTPUT
AS
/*    
	Task : Company winloss report      
	DB:    
	Original:[[AffAdmin_CompanyWinlossReport]]      
	Revisions:
		-20140326@Bobby: Apply paging           
                
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

	--Reset todate to ending of date
	SELECT @ToDate = dbo.Aff_GetEndDate(@ToDate)

	-- Get productid
	DECLARE @SportsbookId INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT

	SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

	SELECT ex.ExchangeId AS CurrencyId
		,ex.Code AS Currency
	INTO #PlayerCurrencies
	FROM [dbo].[strSplit](@PlayerCurrencies, ',') tmp
		INNER JOIN Exchange ex WITH (NOLOCK)
		ON tmp.Val = ex.ExchangeId

	IF (@GroupBy = 0) --Group by Date
	BEGIN
		SELECT ad.Winlostdate
			,p.Currency
			,p.CurrencyId
			,ad.SysExRate AS ExRate
			,exr.AffExRate
			,Sum(ISNULL(ad.MemDeposit, 0)) AS Deposit
			,Sum(ISNULL(ad.MemWithdrawal, 0)) AS Withdrawal
			,Sum(ISNULL(ad.MemBonus, 0)) AS Bonus
			,Sum(ISNULL(ad.MemAdjustment, 0)) AS Adjustment
			,Sum(ISNULL(ad.MemPSP, 0)) AS PSP
			,SUM(CASE 
					WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
					ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
					END) AS Turnover
			,Sum(CASE 
					WHEN ad.ProductID = @SportsbookId THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END) AS SportsbookTurnover
			,Sum(CASE 
					WHEN ad.ProductID = @NumberGame THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END) AS NumberGameTurnover
			,Sum(CASE 
					WHEN ad.ProductID = @LiveCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END) AS LiveCasinoTurnover
			,Sum(CASE 
					WHEN ad.ProductID = @RNGCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END) AS RNGCasinoTurnover
			,CAST(Sum(CASE 
						WHEN @DrawFilter = 1 THEN ISNULL(ad.MemBetCountNoDraw, 0)
						ELSE ISNULL(ad.MemBetCount, 0)
						END) AS INT) AS BetCount
			,CAST(isnull(m.ActivePlayer, 0) AS INT) AS ActivePlayer
			,Sum(ISNULL(ad.MemWinlost, 0)) AS Winlost
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
						ELSE 0
						END)
				) AS SportsbookWinlost
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
						ELSE 0
						END)
				) AS NumberGameWinlost
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
						ELSE 0
						END)
				) AS LiveCasinoWinlost
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
						ELSE 0
						END)
				) AS RNGCasinoWinlost
			,- (Sum(ISNULL(ad.MemWinlost, 0))) AS Total
			,
			--Convert to system currency
			Sum(ISNULL(ad.MemDeposit, 0) * SysExRate) AS DepositBase
			,Sum(ISNULL(ad.MemWithdrawal, 0) * SysExRate) AS WithdrawalBase
			,Sum(ISNULL(ad.MemBonus, 0) * SysExRate) AS BonusBase
			,Sum(ISNULL(ad.MemAdjustment, 0) * SysExRate) AS AdjustmentBase
			,Sum(ISNULL(ad.MemPSP, 0) * SysExRate) AS PSPBase
			,SUM(CASE 
					WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
					ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
					END * SysExRate) AS TurnoverBase
			,Sum(CASE 
					WHEN ad.ProductID = @SportsbookId THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * SysExRate) AS SportsbookTurnoverBase
			,Sum(CASE 
					WHEN ad.ProductID = @NumberGame THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * SysExRate) AS NumberGameTurnoverBase
			,Sum(CASE 
					WHEN ad.ProductID = @LiveCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * SysExRate) AS LiveCasinoTurnoverBase
			,Sum(CASE 
					WHEN ad.ProductID = @RNGCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * SysExRate) AS RNGCasinoTurnoverBase
			,Sum(ad.MemWinlost * SysExRate) AS WinlostBase
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0) * SysExRate
						ELSE 0
						END)
				) AS SportsbookWinlostBase
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0) * SysExRate
						ELSE 0
						END)
				) AS NumberGameWinlostBase
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0) * SysExRate
						ELSE 0
						END)
				) AS LiveCasinoWinlostBase
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0) * SysExRate
						ELSE 0
						END)
				) AS RNGCasinoWinlostBase
			,- (Sum(ISNULL(ad.MemWinlost, 0) * SysExRate)) AS TotalBase
			,
			--Convert to Aff Currency
			Sum(ISNULL(ad.MemDeposit, 0) * ad.AffExRate) AS Deposit_Aff
			,Sum(ISNULL(ad.MemWithdrawal, 0) * ad.AffExRate) AS Withdrawal_Aff
			,Sum(ISNULL(ad.MemBonus, 0) * ad.AffExRate) AS Bonus_Aff
			,Sum(ISNULL(ad.MemAdjustment, 0) * ad.AffExRate) AS Adjustment_Aff
			,Sum(ISNULL(ad.MemPSP, 0) * ad.AffExRate) AS PSP_Aff
			,SUM(CASE 
					WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
					ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
					END * ad.AffExRate) AS Turnover_Aff
			,Sum(CASE 
					WHEN ad.ProductID = @SportsbookId THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * ad.AffExRate) AS SportsbookTurnover_Aff
			,Sum(CASE 
					WHEN ad.ProductID = @NumberGame THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * ad.AffExRate) AS NumberGameTurnover_Aff
			,Sum(CASE 
					WHEN ad.ProductID = @LiveCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * ad.AffExRate) AS LiveCasinoTurnover_Aff
			,Sum(CASE 
					WHEN ad.ProductID = @RNGCasino THEN (CASE 
							WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
							ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
							)
					ELSE 0
					END * ad.AffExRate) AS RNGCasinoTurnover_Aff
			,Sum(ad.MemWinlost * ad.AffExRate) AS Winlost_Aff
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN ad.MemWinlost * ad.AffExRate
						ELSE 0
						END)
				) AS SportsbookWinlost_Aff
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN ad.MemWinlost * ad.AffExRate
						ELSE 0
						END)
				) AS NumberGameWinlost_Aff
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN ad.MemWinlost * ad.AffExRate
						ELSE 0
						END)
				) AS LiveCasinoWinlost_Aff
			,- (
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN ad.MemWinlost * ad.AffExRate
						ELSE 0
						END)
				) AS RNGCasinoWinlost_Aff
			,- (Sum(ad.MemWinlost * ad.AffExRate)) AS Total_Aff
			,ROW_NUMBER() OVER (
				ORDER BY ad.Winlostdate DESC
				) AS RowNum
		INTO #rptWinlossDate
		FROM AffDaily ad WITH (NOLOCK)
			INNER JOIN #PlayerCurrencies AS p
			ON ad.MemCurrency = p.CurrencyId
			INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
			ON ad.AffId = t.AffId
				AND DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
			LEFT JOIN (
			SELECT Winlostdate
				,COUNT(DISTINCT m.Username) AS ActivePlayer
			FROM MemberDaily m WITH (NOLOCK)
				INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
				ON m.AffId = t.AffId
					AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
				AND Turnover > 0
			GROUP BY Winlostdate
			) AS m
			ON DATEDIFF(d, ad.Winlostdate, m.WinlostDate) = 0
			INNER JOIN (
			SELECT DISTINCT AffID
				,Winlostdate
				,CASE @BaseCurrency
					WHEN 2 THEN AffExRate
					ELSE 1
					END AffExRate
			FROM dbo.AffDaily WITH (NOLOCK)
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
			) exr
			ON ad.AffID = exr.AffID
				AND ad.Winlostdate = exr.Winlostdate
		WHERE ad.Winlostdate BETWEEN @FromDate AND @ToDate
		GROUP BY ad.Winlostdate
			,p.Currency
			,p.CurrencyId
			,ad.SysExRate
			,exr.AffExRate
			,m.ActivePlayer
		HAVING SUM(ad.MemDeposit) > 0
			OR SUM(ad.MemWinlost) > 0
			OR SUM(ad.MemBonus) > 0
			OR SUM(ad.MemAdjustment) > 0
			OR SUM(ad.MemTurnover) > 0
		
		SELECT @NRows = count(1)
		FROM #rptWinlossDate rpt

		IF(@NRows = 0) RETURN;

		--select rpt data
		SELECT *
		FROM #rptWinlossDate rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)

		--select sum data by date/MemberCurrency
		SELECT Winlostdate
			,Currency
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
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
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
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
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossDate
		GROUP BY Winlostdate
			, Currency

		--select sum data by MemberCurrency
		SELECT Currency
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
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
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
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
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossDate
		GROUP BY Currency

		--select sum data by SysCurrency
		SELECT SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
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
			,Sum(MemDeposit) AS Deposit
			,Sum(MemWithdrawal) AS Withdrawal
			,Sum(MemBonus) AS Bonus
			,Sum(MemAdjustment) AS Adjustment
			,Sum(MemPSP) AS PSP
			,SUM(Turnover) AS Turnover
			,Sum(SportsbookTurnover) AS SportsbookTurnover
			,Sum(NumberGameTurnover) AS NumberGameTurnover
			,Sum(LiveCasinoTurnover) AS LiveCasinoTurnover
			,Sum(RNGCasinoTurnover) AS RNGCasinoTurnover
			,CAST(Sum(BetCount) AS INT) AS BetCount
			,CAST(Sum(m.ActivePlayer) AS INT) AS ActivePlayer
			,Sum(MemWinlost) AS Winlost
			,Sum(SportsbookWinlost) AS SportsbookWinlost
			,Sum(NumberGameWinlost) AS NumberGameWinlost
			,Sum(LiveCasinoWinlost) AS LiveCasinoWinlost
			,Sum(RNGCasinoWinlost) AS RNGCasinoWinlost
			,Sum(Total) AS Total
			,Sum(MemDepositBase) AS DepositBase
			,Sum(MemWithdrawalBase) AS WithdrawalBase
			,Sum(MemBonusBase) AS BonusBase
			,Sum(MemAdjustmentBase) AS AdjustmentBase
			,Sum(MemPSPBase) AS PSPBase
			,Sum(TurnoverBase) AS TurnoverBase
			,Sum(SportsbookTurnoverBase) AS SportsbookTurnoverBase
			,Sum(NumberGameTurnoverBase) AS NumberGameTurnoverBase
			,Sum(LiveCasinoTurnoverBase) AS LiveCasinoTurnoverBase
			,Sum(RNGCasinoTurnoverBase) AS RNGCasinoTurnoverBase
			,Sum(MemWinlostBase) AS WinlostBase
			,Sum(SportsbookWinlostBase) AS SportsbookWinlostBase
			,Sum(NumberGameWinlostBase) AS NumberGameWinlostBase
			,Sum(LiveCasinoWinlostBase) AS LiveCasinoWinlostBase
			,Sum(RNGCasinoWinlostBase) AS RNGCasinoWinlostBase
			,Sum(TotalBase) AS TotalBase
			,Sum(MemDeposit_Aff) AS Deposit_Aff
			,Sum(MemWithdrawal_Aff) AS Withdrawal_Aff
			,Sum(MemBonus_Aff) AS Bonus_Aff
			,Sum(MemAdjustment_Aff) AS Adjustment_Aff
			,Sum(MemPSP_Aff) AS PSP_Aff
			,Sum(Turnover_Aff) AS Turnover_Aff
			,Sum(SportsbookTurnover_Aff) AS SportsbookTurnover_Aff
			,Sum(NumberGameTurnover_Aff) AS NumberGameTurnover_Aff
			,Sum(LiveCasinoTurnover_Aff) AS LiveCasinoTurnover_Aff
			,Sum(RNGCasinoTurnover_Aff) AS RNGCasinoTurnover_Aff
			,Sum(MemWinlost_Aff) AS Winlost_Aff
			,Sum(SportsbookWinlost_Aff) AS SportsbookWinlost_Aff
			,Sum(NumberGameWinlost_Aff) AS NumberGameWinlost_Aff
			,Sum(LiveCasinoWinlost_Aff) AS LiveCasinoWinlost_Aff
			,Sum(RNGCasinoWinlost_Aff) AS RNGCasinoWinlost_Aff
			,Sum(Total_Aff) AS Total_Aff
			,ROW_NUMBER() OVER (
				ORDER BY tmp.WinlostDate DESC
				) AS RowNum
		INTO #rptWinlossMonth
		FROM (
			SELECT dateadd(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
				,p.Currency
				,p.CurrencyId
				,Sum(ISNULL(ad.MemDeposit, 0)) AS MemDeposit
				,Sum(ISNULL(ad.MemWithdrawal, 0)) AS MemWithdrawal
				,Sum(ISNULL(ad.MemBonus, 0)) AS MemBonus
				,Sum(ISNULL(ad.MemAdjustment, 0)) AS MemAdjustment
				,Sum(ISNULL(ad.MemPSP, 0)) AS MemPSP
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END) AS Turnover
				,Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS SportsbookTurnover
				,Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS NumberGameTurnover
				,Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS LiveCasinoTurnover
				,Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS RNGCasinoTurnover
				,Sum(CASE 
						WHEN @DrawFilter = 1 THEN ISNULL(ad.MemBetCountNoDraw, 0)
						ELSE ISNULL(ad.MemBetCount, 0)
						END) AS BetCount
				,Sum(ISNULL(ad.MemWinlost, 0)) AS MemWinlost
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS SportsbookWinlost
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS NumberGameWinlost
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS LiveCasinoWinlost
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END)
					) AS RNGCasinoWinlost
				,- (Sum(ISNULL(ad.MemWinlost, 0))) AS Total
				,
				--Convert to System ex.Rate
				Sum(ISNULL(ad.MemDeposit, 0) * ad.SysExRate) AS MemDepositBase
				,Sum(ISNULL(ad.MemWithdrawal, 0) * ad.SysExRate) AS MemWithdrawalBase
				,Sum(ISNULL(ad.MemBonus, 0) * ad.SysExRate) AS MemBonusBase
				,Sum(ISNULL(ad.MemAdjustment, 0) * ad.SysExRate) AS MemAdjustmentBase
				,Sum(ISNULL(ad.MemPSP, 0) * ad.SysExRate) AS MemPSPBase
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END * ad.SysExRate) AS TurnoverBase
				,Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS SportsbookTurnoverBase
				,Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS NumberGameTurnoverBase
				,Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS LiveCasinoTurnoverBase
				,Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.SysExRate) AS RNGCasinoTurnoverBase
				,Sum(ISNULL(ad.MemWinlost, 0) * ad.SysExRate) AS MemWinlostBase
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS SportsbookWinlostBase
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS NumberGameWinlostBase
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS LiveCasinoWinlostBase
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.SysExRate)
					) AS RNGCasinoWinlostBase
				,- (Sum(ISNULL(ad.MemWinlost, 0) * ad.SysExRate)) AS TotalBase
				,
				--Convert to Affiliate ex.Rate
				Sum(ISNULL(ad.MemDeposit, 0) * ad.AffExRate) AS MemDeposit_Aff
				,Sum(ISNULL(ad.MemWithdrawal, 0) * ad.AffExRate) AS MemWithdrawal_Aff
				,Sum(ISNULL(ad.MemBonus, 0) * ad.AffExRate) AS MemBonus_Aff
				,Sum(ISNULL(ad.MemAdjustment, 0) * ad.AffExRate) AS MemAdjustment_Aff
				,Sum(ISNULL(ad.MemPSP, 0) * ad.AffExRate) AS MemPSP_Aff
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
						ELSE ISNULL(ad.MemTurnoverNoDraw, 0)
						END * ad.AffExRate) AS Turnover_Aff
				,Sum(CASE 
						WHEN ad.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS SportsbookTurnover_Aff
				,Sum(CASE 
						WHEN ad.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS NumberGameTurnover_Aff
				,Sum(CASE 
						WHEN ad.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS LiveCasinoTurnover_Aff
				,Sum(CASE 
						WHEN ad.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(ad.MemTurnover, 0)
								ELSE ISNULL(ad.MemTurnoverNoDraw, 0) END
								)
						ELSE 0
						END * ad.AffExRate) AS RNGCasinoTurnover_Aff
				,Sum(ISNULL(ad.MemWinlost, 0) * ad.AffExRate) AS MemWinlost_Aff
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @SportsbookId THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS SportsbookWinlost_Aff
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @NumberGame THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS NumberGameWinlost_Aff
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @LiveCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS LiveCasinoWinlost_Aff
				,- (
					Sum(CASE 
							WHEN ad.ProductID = @RNGCasino THEN ISNULL(ad.MemWinlost, 0)
							ELSE 0
							END * ad.AffExRate)
					) AS RNGCasinoWinlost_Aff
				,- (Sum(ISNULL(ad.MemWinlost, 0) * ad.AffExRate)) AS Total_Aff
			FROM AffDaily ad WITH (NOLOCK)
				INNER JOIN #PlayerCurrencies AS p
				ON ad.MemCurrency = p.CurrencyId
				INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
				ON ad.AffId = t.AffId
					AND DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
			GROUP BY dateadd(m, datediff(m, 0, Winlostdate), 0)
				,p.Currency
				,p.CurrencyId
			) AS tmp
			LEFT JOIN (
			SELECT dateadd(m, datediff(m, 0, Winlostdate), 0) AS WinlostDate
				,COUNT(DISTINCT m.Username) AS ActivePlayer
			FROM MemberDaily m WITH (NOLOCK)
				INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
				ON m.AffId = t.AffId
					AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
				AND Turnover > 0
			GROUP BY dateadd(m, datediff(m, 0, Winlostdate), 0)
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

		IF(@NRows = 0) RETURN;

		--select rpt data
		SELECT *
		FROM #rptWinlossMonth rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)

		--select sum data by date/MemberCurrency
		SELECT Winlostdate
			,Currency
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
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
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
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
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossMonth
		GROUP BY Winlostdate
			, Currency

		--select sum data by MemberCurrency
		SELECT Currency
			,SUM(Deposit) Deposit
			,SUM(Withdrawal) Withdrawal
			,SUM(Bonus) Bonus
			,SUM(Adjustment) Adjustment
			,SUM(PSP) PSP
			,SUM(SportsBookTurnover) SportsBookTurnover
			,SUM(NumberGameTurnover) NumberGameTurnover
			,SUM(LiveCasinoTurnover) LiveCasinoTurnover
			,SUM(RNGCasinoTurnover) RNGCasinoTurnover
			,SUM(TotalTurnover) TotalTurnover
			,SUM(SportsBookWinlost) SportsBookWinlost
			,SUM(NumberGameWinlost) NumberGameWinlost
			,SUM(LiveCasinoWinlost) LiveCasinoWinlost
			,SUM(RNGCasinoWinlost) RNGCasinoWinlost
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
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
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
			,SUM(TotalTurnover_Aff) TotalTurnover_Aff
			,SUM(SportsBookWinlost_Aff) SportsBookWinlost_Aff
			,SUM(NumberGameWinlost_Aff) NumberGameWinlost_Aff
			,SUM(LiveCasinoWinlost_Aff) LiveCasinoWinlost_Aff
			,SUM(RNGCasinoWinlost_Aff) RNGCasinoWinlost_Aff
			,SUM(TotalWinlost_Aff) TotalWinlost_Aff
		FROM #rptWinlossMonth
		GROUP BY Currency

		--select sum data by SysCurrency
		SELECT SUM(DepositBase) DepositBase
			,SUM(WithdrawalBase) WithdrawalBase
			,SUM(BonusBase) BonusBase
			,SUM(AdjustmentBase) AdjustmentBase
			,SUM(PSPBase) PSPBase
			,SUM(SportsBookTurnoverBase) SportsBookTurnoverBase
			,SUM(NumberGameTurnoverBase) NumberGameTurnoverBase
			,SUM(LiveCasinoTurnoverBase) LiveCasinoTurnoverBase
			,SUM(RNGCasinoTurnoverBase) RNGCasinoTurnoverBase
			,SUM(TotalTurnoverBase) TotalTurnoverBase
			,SUM(SportsBookWinlostBase) SportsBookWinlostBase
			,SUM(NumberGameWinlostBase) NumberGameWinlostBase
			,SUM(LiveCasinoWinlostBase) LiveCasinoWinlostBase
			,SUM(RNGCasinoWinlostBase) RNGCasinoWinlostBase
			,SUM(TotalWinlostBase) TotalWinlostBase
		FROM #rptWinlossMonth

		DROP TABLE #rptWinlossMonth
	END

	DROP TABLE #PlayerCurrencies
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CompanyWinlossReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CompanyWinlossReport] TO [vnteam] AS [dbo]
