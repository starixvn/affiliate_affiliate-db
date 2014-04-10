ALTER PROCEDURE [dbo].[AffAdmin_PlayerWinlossReport] 
	@UserId INT = 0
	,@AffName NVARCHAR(100) = NULL
	,@AffTypes VARCHAR(100) = NULL
	,@CommGroups VARCHAR(1000) = NULL
	,@PreferLanguages VARCHAR(1000) = NULL
	,@PlayerName NVARCHAR(100) = NULL
	,@GroupBy TINYINT = 0
	,@FromDate DATETIME = NULL
	,@ToDate DATETIME = NULL
	,@PlayerCurrencies VARCHAR(100) = NULL
	,@BaseCurrency TINYINT = 0
	,@DrawFilter TINYINT = 0
	,@ExcludeTest BIT = 1
	,@IsITAdmin BIT = 0
	,@PageCurrent INT = 1
	,@PageSize INT = 25
	,@NRows INT = 0 OUTPUT
AS
/*    
	Task : Player Winloss Report     
	DB:    
	Original:[AffAdmin_PlayerWinlossReport]
	Revisions:           
		-20140326@Bobby: Apply paging           
                
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

	--Reset todate to ending of date
	SELECT @ToDate = dbo.Aff_GetEndDate(@ToDate)
		,@PlayerName = '%' + isnull(@PlayerName, '') + '%'

	-- Get productid
	DECLARE @SportsbookId INT
		,@NumberGame INT
		,@LiveCasino INT
		,@RNGCasino INT

	SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
		,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

	DECLARE @PlayerCurrencyList TABLE (
		ExchangeID INT
		,Code NVARCHAR(50)
		)

	INSERT INTO @PlayerCurrencyList
	SELECT ExchangeID
		,ex.Code
	FROM [dbo].[strSplit](@PlayerCurrencies, ',')
		INNER JOIN Exchange ex(NOLOCK)
		ON ex.ExchangeID = CAST(val AS INT)

	IF (@GroupBy = 0)
	BEGIN
		SELECT tmp.WinlostDate
			,tmp.Username
			,tmp.Currency
			,tmp.PlayerUsername
			,tmp.PlayerCurrency
			,tmp.SysExRate AS ExRate
			,tmp.AffExRate
			,SUM(tmp.Deposit) AS Deposit
			,SUM(tmp.Withdrawal) AS Withdrawal
			,SUM(tmp.Bonus) AS Bonus
			,SUM(ISNULL(tmp.Adjustment, 0)) AS Adjustment
			,SUM(tmp.PSP) AS PSP
			,SUM(tmp.SportsBookTurnover) AS SportsBookTurnover
			,SUM(tmp.NumberGameTurnover) AS NumberGameTurnover
			,SUM(tmp.LiveCasinoTurnover) AS LiveCasinoTurnover
			,SUM(tmp.RNGCasinoTurnover) AS RNGCasinoTurnover
			,SUM(tmp.TotalTurnover) AS TotalTurnover
			,SUM(tmp.SportsBookWinlost) AS SportsBookWinlost
			,SUM(tmp.NumberGameWinlost) AS NumberGameWinlost
			,SUM(tmp.LiveCasinoWinlost) AS LiveCasinoWinlost
			,SUM(tmp.RNGCasinoWinlost) AS RNGCasinoWinlost
			,SUM(tmp.TotalWinlost) AS TotalWinlost
			,Sum(tmp.BetCount) AS BetCount
			--Base currency
			,SUM(tmp.Deposit * tmp.SysExRate) AS DepositBase
			,SUM(tmp.Withdrawal * tmp.SysExRate) AS WithdrawalBase
			,SUM(tmp.Bonus * tmp.SysExRate) AS BonusBase
			,SUM(tmp.Adjustment * tmp.SysExRate) AS AdjustmentBase
			,SUM(tmp.PSP * tmp.SysExRate) AS PSPBase
			,SUM(tmp.SportsBookTurnover * tmp.SysExRate) AS SportsBookTurnoverBase
			,SUM(tmp.NumberGameTurnover * tmp.SysExRate) AS NumberGameTurnoverBase
			,SUM(tmp.LiveCasinoTurnover * tmp.SysExRate) AS LiveCasinoTurnoverBase
			,SUM(tmp.RNGCasinoTurnover * tmp.SysExRate) AS RNGCasinoTurnoverBase
			,SUM(tmp.TotalTurnover * tmp.SysExRate) AS TotalTurnoverBase
			,SUM(tmp.SportsBookWinlost * tmp.SysExRate) AS SportsBookWinlostBase
			,SUM(tmp.NumberGameWinlost * tmp.SysExRate) AS NumberGameWinlostBase
			,SUM(tmp.LiveCasinoWinlost * tmp.SysExRate) AS LiveCasinoWinlostBase
			,SUM(tmp.RNGCasinoWinlost * tmp.SysExRate) AS RNGCasinoWinlostBase
			,SUM(tmp.TotalWinlost * tmp.SysExRate) AS TotalWinlostBase
			--Affiliate currency
			,SUM(tmp.Deposit * tmp.AffExRate) AS Deposit_Aff
			,SUM(tmp.Withdrawal * tmp.AffExRate) AS Withdrawal_Aff
			,SUM(tmp.Bonus * tmp.AffExRate) AS Bonus_Aff
			,SUM(tmp.Adjustment * tmp.AffExRate) AS Adjustment_Aff
			,SUM(tmp.PSP * tmp.AffExRate) AS PSP_Aff
			,SUM(tmp.SportsBookTurnover * tmp.AffExRate) AS SportsBookTurnover_Aff
			,SUM(tmp.NumberGameTurnover * tmp.AffExRate) AS NumberGameTurnover_Aff
			,SUM(tmp.LiveCasinoTurnover * tmp.AffExRate) AS LiveCasinoTurnover_Aff
			,SUM(tmp.RNGCasinoTurnover * tmp.AffExRate) AS RNGCasinoTurnover_Aff
			,SUM(tmp.TotalTurnover * tmp.AffExRate) AS TotalTurnover_Aff
			,SUM(tmp.SportsBookWinlost * tmp.AffExRate) AS SportsBookWinlost_Aff
			,SUM(tmp.NumberGameWinlost * tmp.AffExRate) AS NumberGameWinlost_Aff
			,SUM(tmp.LiveCasinoWinlost * tmp.AffExRate) AS LiveCasinoWinlost_Aff
			,SUM(tmp.RNGCasinoWinlost * tmp.AffExRate) AS RNGCasinoWinlost_Aff
			,SUM(tmp.TotalWinlost * tmp.AffExRate) AS TotalWinlost_Aff
			,ROW_NUMBER() OVER (
				ORDER BY tmp.WinlostDate
				) AS RowNum
		INTO #rptWinlossDate
		FROM (
			SELECT m.WinlostDate
				,t.Username
				,t.Currency
				,m.UserName AS PlayerUsername
				,e.Code AS PlayerCurrency
				,Sum(ISNULL(m.Deposit, 0)) AS Deposit
				,Sum(ISNULL(m.Withdrawal, 0)) AS Withdrawal
				,SUM(ISNULL(m.Bonus, 0)) AS Bonus
				,SUM(ISNULL(m.Adjustment, 0)) AS Adjustment
				,SUM(ISNULL(m.PSP, 0)) AS PSP
				,Sum(CASE 
						WHEN m.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS SportsBookTurnover
				,Sum(CASE 
						WHEN m.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS NumberGameTurnover
				,Sum(CASE 
						WHEN m.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS LiveCasinoTurnover
				,Sum(CASE 
						WHEN m.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS RNGCasinoTurnover
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
						ELSE ISNULL(m.TurnoverNoDraw, 0)
						END) AS TotalTurnover
				,SUM(CASE 
						WHEN @DrawFilter = 1 THEN ISNULL(m.BetCountNoDraw, 0)
						ELSE m.BetCount
						END) AS BetCount
				,SUM(ISNULL(m.Winlost, 0)) AS Winlost
				,- SUM(CASE 
						WHEN m.ProductID = @SportsbookId THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS SportsBookWinlost
				,- SUM(CASE 
						WHEN m.ProductID = @NumberGame THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS NumberGameWinlost
				,- SUM(CASE 
						WHEN m.ProductID = @LiveCasino THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS LiveCasinoWinlost
				,- SUM(CASE 
						WHEN m.ProductID = @RNGCasino THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS RNGCasinoWinlost
				,- (SUM(ISNULL(m.Winlost, 0))) AS TotalWinlost
				,m.SysExRate
				,m.AffExRate
			FROM MemberDaily m WITH (NOLOCK)
				INNER JOIN @PlayerCurrencyList e
				ON m.Currency = e.ExchangeID
				INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
				ON m.AffId = t.AffId
					AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			WHERE WinlostDate BETWEEN @FromDate AND @ToDate
				AND m.UserName LIKE @PlayerName
			GROUP BY m.WinlostDate
				,t.Username
				,t.Currency
				,m.UserName
				,e.Code
				,m.SysExRate
				,m.AffExRate
			) AS tmp
		GROUP BY tmp.WinlostDate
			,tmp.Username
			,tmp.Currency
			,tmp.PlayerUsername
			,tmp.PlayerCurrency
			,tmp.SysExRate
			,tmp.AffExRate

		--set @PageTotal
		SELECT @NRows = count(1)
		FROM #rptWinlossDate rpt
		
		--select data / page
		SELECT *
		FROM #rptWinlossDate rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)

		--select sum data - PlayerCurrency
		SELECT PlayerCurrency
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
		FROM #rptWinlossDate rpt
		GROUP BY PlayerCurrency
		
		--select sum data - SysCurrency
		SELECT SUM(BetCount) BetCount
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
		FROM #rptWinlossDate rpt
		
		DROP TABLE #rptWinlossDate
	END
	ELSE
	BEGIN
		SELECT tmp.Username
			,tmp.Currency
			,tmp.PlayerUsername
			,tmp.PlayerCurrency
			,SUM(tmp.Deposit) AS Deposit
			,SUM(tmp.Withdrawal) AS Withdrawal
			,SUM(tmp.Bonus) AS Bonus
			,SUM(ISNULL(tmp.Adjustment, 0)) AS Adjustment
			,SUM(tmp.PSP) AS PSP
			,SUM(tmp.SportsBookTurnover) AS SportsBookTurnover
			,SUM(tmp.NumberGameTurnover) AS NumberGameTurnover
			,SUM(tmp.LiveCasinoTurnover) AS LiveCasinoTurnover
			,SUM(tmp.RNGCasinoTurnover) AS RNGCasinoTurnover
			,SUM(tmp.TotalTurnover) AS TotalTurnover
			,SUM(tmp.SportsBookWinlost) AS SportsBookWinlost
			,SUM(tmp.NumberGameWinlost) AS NumberGameWinlost
			,SUM(tmp.LiveCasinoWinlost) AS LiveCasinoWinlost
			,SUM(tmp.RNGCasinoWinlost) AS RNGCasinoWinlost
			,SUM(tmp.TotalWinlost) AS TotalWinlost
			,Sum(tmp.BetCount) AS BetCount
			--Base currency
			,SUM(tmp.Deposit * tmp.ExRate) AS DepositBase
			,SUM(tmp.Withdrawal * tmp.ExRate) AS WithdrawalBase
			,SUM(tmp.Bonus * tmp.ExRate) AS BonusBase
			,SUM(tmp.Adjustment * tmp.ExRate) AS AdjustmentBase
			,SUM(tmp.PSP * tmp.ExRate) AS PSPBase
			,SUM(tmp.SportsBookTurnover * tmp.ExRate) AS SportsBookTurnoverBase
			,SUM(tmp.NumberGameTurnover * tmp.ExRate) AS NumberGameTurnoverBase
			,SUM(tmp.LiveCasinoTurnover * tmp.ExRate) AS LiveCasinoTurnoverBase
			,SUM(tmp.RNGCasinoTurnover * tmp.ExRate) AS RNGCasinoTurnoverBase
			,SUM(tmp.TotalTurnover * tmp.ExRate) AS TotalTurnoverBase
			,SUM(tmp.SportsBookWinlost * tmp.ExRate) AS SportsBookWinlostBase
			,SUM(tmp.NumberGameWinlost * tmp.ExRate) AS NumberGameWinlostBase
			,SUM(tmp.LiveCasinoWinlost * tmp.ExRate) AS LiveCasinoWinlostBase
			,SUM(tmp.RNGCasinoWinlost * tmp.ExRate) AS RNGCasinoWinlostBase
			,SUM(tmp.TotalWinlost * tmp.ExRate) AS TotalWinlostBase
			--Affiliate currency
			,SUM(tmp.Deposit * tmp.AffExRate) AS Deposit_Aff
			,SUM(tmp.Withdrawal * tmp.AffExRate) AS Withdrawal_Aff
			,SUM(tmp.Bonus * tmp.AffExRate) AS Bonus_Aff
			,SUM(tmp.Adjustment * tmp.AffExRate) AS Adjustment_Aff
			,SUM(tmp.PSP * tmp.AffExRate) AS PSP_Aff
			,SUM(tmp.SportsBookTurnover * tmp.AffExRate) AS SportsBookTurnover_Aff
			,SUM(tmp.NumberGameTurnover * tmp.AffExRate) AS NumberGameTurnover_Aff
			,SUM(tmp.LiveCasinoTurnover * tmp.AffExRate) AS LiveCasinoTurnover_Aff
			,SUM(tmp.RNGCasinoTurnover * tmp.AffExRate) AS RNGCasinoTurnover_Aff
			,SUM(tmp.TotalTurnover * tmp.AffExRate) AS TotalTurnover_Aff
			,SUM(tmp.SportsBookWinlost * tmp.AffExRate) AS SportsBookWinlost_Aff
			,SUM(tmp.NumberGameWinlost * tmp.AffExRate) AS NumberGameWinlost_Aff
			,SUM(tmp.LiveCasinoWinlost * tmp.AffExRate) AS LiveCasinoWinlost_Aff
			,SUM(tmp.RNGCasinoWinlost * tmp.AffExRate) AS RNGCasinoWinlost_Aff
			,SUM(tmp.TotalWinlost * tmp.AffExRate) AS TotalWinlost_Aff
			,ROW_NUMBER() OVER (
				ORDER BY tmp.Username
				) AS RowNum
		INTO #rptWinlossPlayer
		FROM (
			SELECT t.Username
				,t.Currency
				,m.UserName AS PlayerUsername
				,e.Code AS PlayerCurrency
				,Sum(ISNULL(m.Deposit, 0)) AS Deposit
				,Sum(ISNULL(m.Withdrawal, 0)) AS Withdrawal
				,SUM(ISNULL(m.Bonus, 0)) AS Bonus
				,SUM(ISNULL(m.Adjustment, 0)) AS Adjustment
				,SUM(ISNULL(m.PSP, 0)) AS PSP
				,Sum(CASE 
						WHEN m.ProductID = @SportsbookId THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS SportsBookTurnover
				,Sum(CASE 
						WHEN m.ProductID = @NumberGame THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS NumberGameTurnover
				,Sum(CASE 
						WHEN m.ProductID = @LiveCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS LiveCasinoTurnover
				,Sum(CASE 
						WHEN m.ProductID = @RNGCasino THEN (CASE 
								WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
								ELSE ISNULL(m.TurnoverNoDraw, 0) END
								)
						ELSE 0
						END) AS RNGCasinoTurnover
				,SUM(CASE 
						WHEN @DrawFilter = 0 THEN ISNULL(m.Turnover, 0)
						ELSE ISNULL(m.TurnoverNoDraw, 0)
						END) AS TotalTurnover
				,SUM(CASE 
						WHEN @DrawFilter = 1 THEN ISNULL(m.BetCountNoDraw, 0)
						ELSE ISNULL(m.BetCount, 0)
						END) AS BetCount
				,SUM(ISNULL(m.Winlost, 0)) AS Winlost
				,- Sum(CASE 
						WHEN m.ProductID = @SportsbookId THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS SportsBookWinlost
				,- Sum(CASE 
						WHEN m.ProductID = @NumberGame THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS NumberGameWinlost
				,- Sum(CASE 
						WHEN m.ProductID = @LiveCasino THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS LiveCasinoWinlost
				,- Sum(CASE 
						WHEN m.ProductID = @RNGCasino THEN ISNULL(m.Winlost, 0)
						ELSE 0
						END) AS RNGCasinoWinlost
				,- (SUM(ISNULL(m.Winlost, 0))) AS TotalWinlost
				,m.SysExRate AS ExRate
				,m.AffExRate AS AffExRate
			FROM MemberDaily m WITH (NOLOCK)
				INNER JOIN @PlayerCurrencyList e
				ON m.Currency = e.ExchangeID
				INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
				ON m.AffId = t.AffId
					AND DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			WHERE WinlostDate BETWEEN @FromDate AND @ToDate
				AND m.UserName LIKE @PlayerName
			GROUP BY t.Username
				,t.Currency
				,m.UserName
				,e.Code
				,m.SysExRate
				,m.AffExRate
			) AS tmp
		GROUP BY tmp.Username
			,tmp.Currency
			,tmp.PlayerUsername
			,tmp.PlayerCurrency
		
		--select PageTotal
		SELECT @NRows = count(1)
		FROM #rptWinlossPlayer rpt
		
		--select data/PageSize
		SELECT *
		FROM #rptWinlossPlayer rpt
		WHERE rpt.RowNum BETWEEN ((@PageCurrent - 1) * @PageSize) + 1 AND @PageSize * (@PageCurrent)
		
		--select sum data - PlayerCurrency
		SELECT PlayerCurrency
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
		FROM #rptWinlossPlayer rpt
		GROUP BY PlayerCurrency
		
		--select sum data - SysCurrency
		SELECT SUM(BetCount) BetCount
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
		FROM #rptWinlossPlayer rpt

		DROP TABLE #rptWinlossPlayer
	END
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_PlayerWinlossReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PlayerWinlossReport] TO [vnteam] AS [dbo]
