ALTER PROCEDURE [dbo].[AffAdmin_PlayerWinlossReport]
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@PlayerName nvarchar(100) = NULL,
	@GroupBy tinyint = 0,
	@FromDate datetime = NULL,
	@ToDate datetime = NULL,
	@PlayerCurrencies varchar(100) = NULL,
	@BaseCurrency tinyint = 0,
	@DrawFilter tinyint = 0,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0
AS

/*    
Task : Player Winloss Report     
DB:    
Original:[AffAdmin_PlayerWinlossReport]
Revisions:           
                
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
SET NOCOUNT ON 

--Reset todate to ending of date
SELECT	@ToDate = dbo.Aff_GetEndDate(@ToDate)
		, @PlayerName = '%' + isnull(@PlayerName, '') + '%'
-- Get productid
Declare @SportsbookId int, @NumberGame int, @LiveCasino int, @RNGCasino int
Select	@SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
		, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

DECLARE @PlayerCurrencyList TABLE (ExchangeID INT, Code nvarchar(50))
INSERT INTO @PlayerCurrencyList
SELECT ExchangeID, ex.Code
FROM [dbo].[strSplit] (@PlayerCurrencies, ',' )
	INNER JOIN Exchange ex (NOLOCK) ON ex.ExchangeID = CAST(val AS INT)


IF(@GroupBy = 0)
Begin
	Select	tmp.WinlostDate
			, tmp.Username
			, tmp.Currency
			, tmp.PlayerUsername
			, tmp.PlayerCurrency
			, tmp.SysExRate as ExRate
			, tmp.AffExRate
			, SUM(tmp.Deposit) as Deposit
			, SUM(tmp.Withdrawal) as Withdrawal
			, SUM(tmp.Bonus) as Bonus
			, SUM(ISNULL(tmp.Adjustment, 0)) as Adjustment
			, SUM(tmp.PSP) as PSP
			, SUM(tmp.SportsBookTurnover) as SportsBookTurnover
			, SUM(tmp.NumberGameTurnover) as NumberGameTurnover
			, SUM(tmp.LiveCasinoTurnover) as LiveCasinoTurnover
			, SUM(tmp.RNGCasinoTurnover) as RNGCasinoTurnover
			, SUM(tmp.TotalTurnover) as TotalTurnover
			, SUM(tmp.SportsBookWinlost) as SportsBookWinlost
			, SUM(tmp.NumberGameWinlost) as NumberGameWinlost
			, SUM(tmp.LiveCasinoWinlost) as LiveCasinoWinlost
			, SUM(tmp.RNGCasinoWinlost) as RNGCasinoWinlost
			, SUM(tmp.TotalWinlost) as TotalWinlost
			, Sum(tmp.BetCount)	as BetCount	
			--Base currency
			, SUM(tmp.Deposit * tmp.SysExRate) as DepositBase
			, SUM(tmp.Withdrawal * tmp.SysExRate) as WithdrawalBase
			, SUM(tmp.Bonus * tmp.SysExRate) as BonusBase
			, SUM(tmp.Adjustment * tmp.SysExRate) as AdjustmentBase
			, SUM(tmp.PSP * tmp.SysExRate) as PSPBase
			, SUM(tmp.SportsBookTurnover * tmp.SysExRate) as SportsBookTurnoverBase
			, SUM(tmp.NumberGameTurnover * tmp.SysExRate) as NumberGameTurnoverBase
			, SUM(tmp.LiveCasinoTurnover * tmp.SysExRate) as LiveCasinoTurnoverBase
			, SUM(tmp.RNGCasinoTurnover * tmp.SysExRate) as RNGCasinoTurnoverBase
			, SUM(tmp.TotalTurnover * tmp.SysExRate) as TotalTurnoverBase
			, SUM(tmp.SportsBookWinlost * tmp.SysExRate) as SportsBookWinlostBase
			, SUM(tmp.NumberGameWinlost * tmp.SysExRate) as NumberGameWinlostBase
			, SUM(tmp.LiveCasinoWinlost * tmp.SysExRate) as LiveCasinoWinlostBase
			, SUM(tmp.RNGCasinoWinlost * tmp.SysExRate) as RNGCasinoWinlostBase
			, SUM(tmp.TotalWinlost * tmp.SysExRate) as TotalWinlostBase
			--Affiliate currency
			, SUM(tmp.Deposit * tmp.AffExRate) as Deposit_Aff
			, SUM(tmp.Withdrawal * tmp.AffExRate) as Withdrawal_Aff
			, SUM(tmp.Bonus * tmp.AffExRate) as Bonus_Aff
			, SUM(tmp.Adjustment * tmp.AffExRate) as Adjustment_Aff
			, SUM(tmp.PSP * tmp.AffExRate) as PSP_Aff
			, SUM(tmp.SportsBookTurnover * tmp.AffExRate) as SportsBookTurnover_Aff
			, SUM(tmp.NumberGameTurnover * tmp.AffExRate) as NumberGameTurnover_Aff
			, SUM(tmp.LiveCasinoTurnover * tmp.AffExRate) as LiveCasinoTurnover_Aff
			, SUM(tmp.RNGCasinoTurnover * tmp.AffExRate) as RNGCasinoTurnover_Aff
			, SUM(tmp.TotalTurnover * tmp.AffExRate) as TotalTurnover_Aff
			, SUM(tmp.SportsBookWinlost * tmp.AffExRate) as SportsBookWinlost_Aff
			, SUM(tmp.NumberGameWinlost * tmp.AffExRate) as NumberGameWinlost_Aff
			, SUM(tmp.LiveCasinoWinlost * tmp.AffExRate) as LiveCasinoWinlost_Aff
			, SUM(tmp.RNGCasinoWinlost * tmp.AffExRate) as RNGCasinoWinlost_Aff
			, SUM(tmp.TotalWinlost * tmp.AffExRate) as TotalWinlost_Aff
	From
		(Select	
				m.WinlostDate
				, t.Username
				, t.Currency
				, m.UserName as PlayerUsername
				, e.Code as PlayerCurrency
				, Sum(m.Deposit) as Deposit
				, Sum(m.Withdrawal) as Withdrawal
				, SUM(m.Bonus) as Bonus
				, SUM(m.Adjustment) as Adjustment
				, SUM(m.PSP) as PSP
				, Sum(CASE 
						WHEN m.ProductID = @SportsbookId then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as SportsBookTurnover
				, Sum(CASE 
						WHEN m.ProductID = @NumberGame then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as NumberGameTurnover
				, Sum(CASE 
						WHEN m.ProductID = @LiveCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as LiveCasinoTurnover
				, Sum(CASE 
						WHEN m.ProductID = @RNGCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END )as RNGCasinoTurnover
				, SUM(CASE WHEN @DrawFilter = 0 THEN m.Turnover ELSE m.TurnoverNoDraw End) as TotalTurnover
				, SUM(CASE WHEN @DrawFilter = 1 THEN m.BetCountNoDraw ELSE m.BetCount End) as BetCount
				, SUM(m.Winlost) as Winlost
				, -SUM(CASE 
						WHEN m.ProductID = @SportsbookId then 
							m.Winlost
						ELSE 0 
					END) as SportsBookWinlost
				, -SUM(CASE 
						WHEN m.ProductID = @NumberGame then 
							m.Winlost
						ELSE 0 
					END) as NumberGameWinlost
				, -SUM(CASE 
						WHEN m.ProductID = @LiveCasino then 
							m.Winlost
						ELSE 0 
					END) as LiveCasinoWinlost
				, -SUM(CASE 
						WHEN m.ProductID = @RNGCasino then 
							m.Winlost
						ELSE 0 
					END )as RNGCasinoWinlost
				, -(SUM(m.Winlost)) as TotalWinlost
				, m.SysExRate
				, m.AffExRate
		From MemberDaily m with (NOLOCK)
			inner JOIN @PlayerCurrencyList e ON m.Currency = e.ExchangeID
			inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
								as t on m.AffId = t.AffId and DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
		where WinlostDate between @FromDate AND @ToDate
				and m.UserName LIKE @PlayerName
		Group by m.WinlostDate
				, t.Username
				, t.Currency
				, m.UserName
				, e.Code 
				, m.SysExRate
				, m.AffExRate
		) as tmp
	
	group BY tmp.WinlostDate
			, tmp.Username
			, tmp.Currency
			, tmp.PlayerUsername
			, tmp.PlayerCurrency
			, tmp.SysExRate
			, tmp.AffExRate
End
Else
Begin
	Select	tmp.Username
			, tmp.Currency
			, tmp.PlayerUsername
			, tmp.PlayerCurrency
			, SUM(tmp.Deposit) as Deposit
			, SUM(tmp.Withdrawal) as Withdrawal
			, SUM(tmp.Bonus) as Bonus
			, SUM(ISNULL(tmp.Adjustment, 0)) as Adjustment
			, SUM(tmp.PSP) as PSP
			, SUM(tmp.SportsBookTurnover) as SportsBookTurnover
			, SUM(tmp.NumberGameTurnover) as NumberGameTurnover
			, SUM(tmp.LiveCasinoTurnover) as LiveCasinoTurnover
			, SUM(tmp.RNGCasinoTurnover) as RNGCasinoTurnover
			, SUM(tmp.TotalTurnover) as TotalTurnover
			, SUM(tmp.SportsBookWinlost) as SportsBookWinlost
			, SUM(tmp.NumberGameWinlost) as NumberGameWinlost
			, SUM(tmp.LiveCasinoWinlost) as LiveCasinoWinlost
			, SUM(tmp.RNGCasinoWinlost) as RNGCasinoWinlost
			, SUM(tmp.TotalWinlost) as TotalWinlost
			, Sum(tmp.BetCount)	as BetCount	
			--Base currency
			, SUM(tmp.Deposit * tmp.ExRate) as DepositBase
			, SUM(tmp.Withdrawal * tmp.ExRate) as WithdrawalBase
			, SUM(tmp.Bonus * tmp.ExRate) as BonusBase
			, SUM(tmp.Adjustment * tmp.ExRate) as AdjustmentBase
			, SUM(tmp.PSP * tmp.ExRate) as PSPBase
			, SUM(tmp.SportsBookTurnover * tmp.ExRate) as SportsBookTurnoverBase
			, SUM(tmp.NumberGameTurnover * tmp.ExRate) as NumberGameTurnoverBase
			, SUM(tmp.LiveCasinoTurnover * tmp.ExRate) as LiveCasinoTurnoverBase
			, SUM(tmp.RNGCasinoTurnover * tmp.ExRate) as RNGCasinoTurnoverBase
			, SUM(tmp.TotalTurnover * tmp.ExRate) as TotalTurnoverBase
			, SUM(tmp.SportsBookWinlost * tmp.ExRate) as SportsBookWinlostBase
			, SUM(tmp.NumberGameWinlost * tmp.ExRate) as NumberGameWinlostBase
			, SUM(tmp.LiveCasinoWinlost * tmp.ExRate) as LiveCasinoWinlostBase
			, SUM(tmp.RNGCasinoWinlost * tmp.ExRate) as RNGCasinoWinlostBase
			, SUM(tmp.TotalWinlost * tmp.ExRate) as TotalWinlostBase
			--Affiliate currency
			, SUM(tmp.Deposit * tmp.AffExRate) as Deposit_Aff
			, SUM(tmp.Withdrawal * tmp.AffExRate) as Withdrawal_Aff
			, SUM(tmp.Bonus * tmp.AffExRate) as Bonus_Aff
			, SUM(tmp.Adjustment * tmp.AffExRate) as Adjustment_Aff
			, SUM(tmp.PSP * tmp.AffExRate) as PSP_Aff
			, SUM(tmp.SportsBookTurnover * tmp.AffExRate) as SportsBookTurnover_Aff
			, SUM(tmp.NumberGameTurnover * tmp.AffExRate) as NumberGameTurnover_Aff
			, SUM(tmp.LiveCasinoTurnover * tmp.AffExRate) as LiveCasinoTurnover_Aff
			, SUM(tmp.RNGCasinoTurnover * tmp.AffExRate) as RNGCasinoTurnover_Aff
			, SUM(tmp.TotalTurnover * tmp.AffExRate) as TotalTurnover_Aff
			, SUM(tmp.SportsBookWinlost * tmp.AffExRate) as SportsBookWinlost_Aff
			, SUM(tmp.NumberGameWinlost * tmp.AffExRate) as NumberGameWinlost_Aff
			, SUM(tmp.LiveCasinoWinlost * tmp.AffExRate) as LiveCasinoWinlost_Aff
			, SUM(tmp.RNGCasinoWinlost * tmp.AffExRate) as RNGCasinoWinlost_Aff
			, SUM(tmp.TotalWinlost * tmp.AffExRate) as TotalWinlost_Aff
	From
		(Select	
				t.Username
				, t.Currency
				, m.UserName as PlayerUsername
				, e.Code as PlayerCurrency
				, Sum(m.Deposit) as Deposit
				, Sum(m.Withdrawal) as Withdrawal
				, SUM(m.Bonus) as Bonus
				, SUM(ISNULL(m.Adjustment, 0)) as Adjustment
				, SUM(m.PSP) as PSP
				, Sum(CASE 
						WHEN m.ProductID = @SportsbookId then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as SportsBookTurnover
				, Sum(CASE 
						WHEN m.ProductID = @NumberGame then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as NumberGameTurnover
				, Sum(CASE 
						WHEN m.ProductID = @LiveCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END) as LiveCasinoTurnover
				, Sum(CASE 
						WHEN m.ProductID = @RNGCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								m.Turnover 
							ELSE
								m.TurnoverNoDraw
							End)
						ELSE 0 
					END )as RNGCasinoTurnover
				, SUM(CASE WHEN @DrawFilter = 0 THEN m.Turnover ELSE m.TurnoverNoDraw End) as TotalTurnover
				, SUM(CASE WHEN @DrawFilter = 1 THEN m.BetCountNoDraw ELSE m.BetCount End) as BetCount
				, SUM(m.Winlost) as Winlost
				,- Sum(CASE 
						WHEN m.ProductID = @SportsbookId then 
							m.Winlost
						ELSE 0 
					END) as SportsBookWinlost
				, -Sum(CASE 
						WHEN m.ProductID = @NumberGame then 
							m.Winlost
						ELSE 0 
					END) as NumberGameWinlost
				, -Sum(CASE 
						WHEN m.ProductID = @LiveCasino then 
							m.Winlost
						ELSE 0 
					END) as LiveCasinoWinlost
				, -Sum(CASE 
						WHEN m.ProductID = @RNGCasino then 
							m.Winlost
						ELSE 0 
					END )as RNGCasinoWinlost
				, -(SUM(m.Winlost)) as TotalWinlost
				, m.SysExRate as ExRate
				, m.AffExRate as AffExRate
		From MemberDaily m with (NOLOCK)
			inner JOIN @PlayerCurrencyList e ON m.Currency = e.ExchangeID
			inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
								as t on m.AffId = t.AffId and DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
		where WinlostDate between @FromDate AND @ToDate
			and m.UserName LIKE @PlayerName
		Group by t.Username
				, t.Currency
				, m.UserName
				, e.Code 
				, m.SysExRate
				, m.AffExRate
		) as tmp
	
	group BY tmp.Username
			, tmp.Currency
			, tmp.PlayerUsername
			, tmp.PlayerCurrency
End
			

GO
GRANT EXECUTE ON [dbo].[AffAdmin_PlayerWinlossReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PlayerWinlossReport] TO [vnteam] AS [dbo]