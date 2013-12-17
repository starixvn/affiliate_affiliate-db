ALTER PROCEDURE [dbo].[AffAdmin_CompanyWinlossReport]
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@PlayerCurrencies varchar(100) = NULL,
	@GroupBy tinyint = 0,
	@FromDate datetime = NULL,
	@ToDate datetime = NULL,
	@DrawFilter tinyint = 0,
	@BaseCurrency tinyint = 0,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0
AS

/*    
Task : Company winloss report      
DB:    
Original:[[AffAdmin_CompanyWinlossReport]]      
Revisions:           
                
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
SET NOCOUNT ON 


--Reset todate to ending of date
SELECT @ToDate = dbo.Aff_GetEndDate(@ToDate)

-- Get productid
Declare @SportsbookId int, @NumberGame int, @LiveCasino int, @RNGCasino int
Select	@SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
		, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

Select ex.ExchangeId as CurrencyId, ex.Code AS Currency
Into #PlayerCurrencies
From [dbo].[strSplit](@PlayerCurrencies, ',') tmp
	INNER JOIN Exchange ex with (nolock) on tmp.Val = ex.ExchangeId


IF(@GroupBy = 0)--Group by Date
Begin
	Select	
		ad.Winlostdate,
		p.Currency,
		p.CurrencyId,
		ad.SysExRate as ExRate,
		CAST(Sum(ISNULL(ad.MemDeposit,0))AS money) as Deposit,
		Sum(ad.MemWithdrawal) as Withdrawal,
		Sum(ad.MemBonus) as Bonus,
		Sum(ad.MemAdjustment) as Adjustment,
		Sum(ad.MemPSP) as PSP,
		SUM(CASE WHEN @DrawFilter = 0 THEN
				ad.MemTurnover 
			ELSE
				ad.MemTurnoverNoDraw
			End) as Turnover,
		Sum(CASE 
				WHEN ad.ProductID = @SportsbookId then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END) as SportsBookTurnover,
		Sum(CASE 
				WHEN ad.ProductID = @NumberGame then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END) as NumberGameTurnover,
		Sum(CASE 
				WHEN ad.ProductID = @LiveCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END) as LiveCasinoTurnover,
		Sum(CASE 
				WHEN ad.ProductID = @RNGCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END)as RNGCasinoTurnover,
		CAST(Sum(CASE 
				WHEN @DrawFilter = 1 THEN ad.MemBetCountNoDraw
				ELSE ad.MemBetCount  
			END) AS int) as BetCount,
		CAST(isnull(m.ActivePlayer, 0) AS int) as ActivePlayer,
		Sum(ad.MemWinlost) as Winlost,
		-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost ELSE 0 END)) as SportsBookWinlost,
		-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost ELSE 0 END )) as NumberGameWinlost,
		-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost ELSE 0 END)) as LiveCasinoWinlost,
		-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost ELSE 0 END)) as RNGCasinoWinlost,
		-(Sum(ad.MemWinlost)) as Total,
		
		--Convert to system currency
		Sum(ad.MemDeposit * SysExRate) as DepositBase,
		Sum(ad.MemWithdrawal * SysExRate) as WithdrawalBase,
		Sum(ad.MemBonus * SysExRate) as BonusBase,
		Sum(ad.MemAdjustment * SysExRate) as AdjustmentBase,
		Sum(ad.MemPSP * SysExRate) as PSPBase,
		SUM(CASE WHEN @DrawFilter = 0 THEN
				ad.MemTurnover 
			ELSE
				ad.MemTurnoverNoDraw
			End * SysExRate) as TurnoverBase,
		Sum(CASE 
				WHEN ad.ProductID = @SportsbookId then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * SysExRate) as SportsBookTurnoverBase,
		Sum(CASE 
				WHEN ad.ProductID = @NumberGame then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * SysExRate) as NumberGameTurnoverBase,
		Sum(CASE 
				WHEN ad.ProductID = @LiveCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * SysExRate) as LiveCasinoTurnoverBase,
		Sum(CASE 
				WHEN ad.ProductID = @RNGCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * SysExRate)as RNGCasinoTurnoverBase,
		Sum(ad.MemWinlost * SysExRate) as WinlostBase,
		-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost * SysExRate ELSE 0 END)) as SportsBookWinlostBase,
		-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost * SysExRate ELSE 0 END)) as NumberGameWinlostBase,
		-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost * SysExRate ELSE 0 END)) as LiveCasinoWinlostBase,
		-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost * SysExRate ELSE 0 END)) as RNGCasinoWinlostBase,
		-(Sum(ad.MemWinlost * SysExRate)) as TotalBase,

		--Convert to Aff Currency
		Sum(ad.MemDeposit * AffExRate) as Deposit_Aff,
		Sum(ad.MemWithdrawal * AffExRate) as Withdrawal_Aff,
		Sum(ad.MemBonus * AffExRate) as Bonus_Aff,
		Sum(ad.MemAdjustment * AffExRate) as Adjustment_Aff,
		Sum(ad.MemPSP * AffExRate) as PSP_Aff,
		SUM(CASE WHEN @DrawFilter = 0 THEN
				ad.MemTurnover 
			ELSE
				ad.MemTurnoverNoDraw
			End * AffExRate) as Turnover_Aff,
		Sum(CASE 
				WHEN ad.ProductID = @SportsbookId then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * AffExRate) as SportsBookTurnover_Aff,
		Sum(CASE 
				WHEN ad.ProductID = @NumberGame then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * AffExRate) as NumberGameTurnover_Aff,
		Sum(CASE 
				WHEN ad.ProductID = @LiveCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * AffExRate) as LiveCasinoTurnover_Aff,
		Sum(CASE 
				WHEN ad.ProductID = @RNGCasino then 
					(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End)
				ELSE 0 
			END * AffExRate)as RNGCasinoTurnover_Aff,
		Sum(ad.MemWinlost * AffExRate) as Winlost_Aff,
		-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost * AffExRate ELSE 0 END)) as SportsBookWinlost_Aff,
		-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost * AffExRate ELSE 0 END)) as NumberGameWinlost_Aff,
		-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost * AffExRate ELSE 0 END)) as LiveCasinoWinlost_Aff,
		-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost * AffExRate ELSE 0 END)) as RNGCasinoWinlost_Aff,
		-(Sum(ad.MemWinlost * AffExRate)) as Total_Aff
	From AffDaily ad with (nolock)
		inner JOIN #PlayerCurrencies as p ON ad.MemCurrency = p.CurrencyId
		inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
					as t on ad.AffId = t.AffId and DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
		LEFT JOIN 
		(
			Select	Winlostdate
					, COUNT(DISTINCT m.Username) as ActivePlayer
			From MemberDaily m WITH (NOLOCK) 
				inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
							as t on m.AffId = t.AffId  and DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			where Winlostdate between @FromDate and @ToDate
				AND Turnover > 0
			GROUP  by Winlostdate
		) as m ON DATEDIFF(d, ad.Winlostdate, m.WinlostDate) = 0	
	where ad.Winlostdate between @FromDate and @ToDate
	Group by ad.Winlostdate
			, p.Currency
			, p.CurrencyId
			, ad.SysExRate
			, ad.AffExRate
			, m.ActivePlayer
End
Else
Begin --By Month
	Select 
		tmp.WinlostDate,
		tmp.Currency,
		tmp.CurrencyId,
		CAST(1 AS float) as ExRate,
		Sum(MemDeposit) as Deposit,
		Sum(MemWithdrawal) as Withdrawal,
		Sum(MemBonus) as Bonus,
		Sum(MemAdjustment) as Adjustment,
		Sum(MemPSP) as PSP,
		SUM(Turnover) as Turnover,
		Sum(SportsBookTurnover) as SportsBookTurnover,
		Sum(NumberGameTurnover) as NumberGameTurnover,
		Sum(LiveCasinoTurnover) as LiveCasinoTurnover,
		Sum(RNGCasinoTurnover)as RNGCasinoTurnover,
		CAST(Sum(BetCount) AS int) as BetCount,
		CAST(Sum(m.ActivePlayer) AS int) as ActivePlayer,
		Sum(MemWinlost) as Winlost,
		Sum(SportsBookWinlost) as SportsBookWinlost,
		Sum(NumberGameWinlost) as NumberGameWinlost,
		Sum(LiveCasinoWinlost) as LiveCasinoWinlost,
		Sum(RNGCasinoWinlost) as RNGCasinoWinlost,
		Sum(Total) as Total,
		Sum(MemDepositBase) as DepositBase,
		Sum(MemWithdrawalBase) as WithdrawalBase,
		Sum(MemBonusBase) as BonusBase,
		Sum(MemAdjustmentBase) as AdjustmentBase,
		Sum(MemPSPBase) as PSPBase,
		Sum(TurnoverBase) as TurnoverBase,
		Sum(SportsBookTurnoverBase) as SportsBookTurnoverBase,
		Sum(NumberGameTurnoverBase) as NumberGameTurnoverBase,
		Sum(LiveCasinoTurnoverBase) as LiveCasinoTurnoverBase,
		Sum(RNGCasinoTurnoverBase)as RNGCasinoTurnoverBase,
		Sum(MemWinlostBase) as WinlostBase,
		Sum(SportsBookWinlostBase) as SportsBookWinlostBase,
		Sum(NumberGameWinlostBase) as NumberGameWinlostBase,
		Sum(LiveCasinoWinlostBase) as LiveCasinoWinlostBase,
		Sum(RNGCasinoWinlostBase) as RNGCasinoWinlostBase,
		Sum(TotalBase) as TotalBase,

		
		Sum(MemDeposit_Aff) as Deposit_Aff,
		Sum(MemWithdrawal_Aff) as Withdrawal_Aff,
		Sum(MemBonus_Aff) as Bonus_Aff,
		Sum(MemAdjustment_Aff) as Adjustment_Aff,
		Sum(MemPSP_Aff) as PSP_Aff,
		Sum(Turnover_Aff) as Turnover_Aff,
		Sum(SportsBookTurnover_Aff) as SportsBookTurnover_Aff,
		Sum(NumberGameTurnover_Aff) as NumberGameTurnover_Aff,
		Sum(LiveCasinoTurnover_Aff) as LiveCasinoTurnover_Aff,
		Sum(RNGCasinoTurnover_Aff)as RNGCasinoTurnover_Aff,
		Sum(MemWinlost_Aff) as Winlost_Aff,
		Sum(SportsBookWinlost_Aff) as SportsBookWinlost_Aff,
		Sum(NumberGameWinlost_Aff) as NumberGameWinlost_Aff,
		Sum(LiveCasinoWinlost_Aff) as LiveCasinoWinlost_Aff,
		Sum(RNGCasinoWinlost_Aff) as RNGCasinoWinlost_Aff,
		Sum(Total_Aff) as Total_Aff

	from (
			Select	
				dateadd(m, datediff(m, 0, Winlostdate), 0) as WinlostDate,
				p.Currency, 
				p.CurrencyId,
				Sum(ad.MemDeposit) as MemDeposit,
				Sum(ad.MemWithdrawal) as MemWithdrawal,
				Sum(ad.MemBonus) as MemBonus,
				Sum(ad.MemAdjustment) as MemAdjustment,
				Sum(ad.MemPSP) as MemPSP,
				SUM(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End) as Turnover,
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END) as SportsBookTurnover,
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END) as NumberGameTurnover,
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END) as LiveCasinoTurnover,
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END )as RNGCasinoTurnover,
				Sum(CASE 
						WHEN @DrawFilter = 1 THEN ad.MemBetCountNoDraw
						ELSE ad.MemBetCount  
					END) as BetCount,
				Sum(ad.MemWinlost) as MemWinlost,
				-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost ELSE 0 END )) as SportsBookWinlost,
				-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost ELSE 0 END )) as NumberGameWinlost,
				-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost ELSE 0 END)) as LiveCasinoWinlost,
				-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost ELSE 0 END)) as RNGCasinoWinlost,
				-(Sum(ad.MemWinlost)) as Total,

				--Convert to System ex.Rate
				Sum(ad.MemDeposit * ad.SysExRate) as MemDepositBase,
				Sum(ad.MemWithdrawal * ad.SysExRate) as MemWithdrawalBase,
				Sum(ad.MemBonus * ad.SysExRate) as MemBonusBase,
				Sum(ad.MemAdjustment * ad.SysExRate) as MemAdjustmentBase,
				Sum(ad.MemPSP * ad.SysExRate) as MemPSPBase,
				SUM(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End * ad.SysExRate) as TurnoverBase,
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.SysExRate) as SportsBookTurnoverBase,
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.SysExRate) as NumberGameTurnoverBase,
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.SysExRate) as LiveCasinoTurnoverBase,
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END  * ad.SysExRate)as RNGCasinoTurnoverBase,
				Sum(ad.MemWinlost * ad.SysExRate) as MemWinlostBase,
				-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost ELSE 0 END  * ad.SysExRate)) as SportsBookWinlostBase,
				-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost ELSE 0 END  * ad.SysExRate)) as NumberGameWinlostBase,
				-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost ELSE 0 END * ad.SysExRate)) as LiveCasinoWinlostBase,
				-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost ELSE 0 END * ad.SysExRate)) as RNGCasinoWinlostBase,
				-(Sum(ad.MemWinlost * ad.SysExRate)) as TotalBase,

				--Convert to Affiliate ex.Rate
				Sum(ad.MemDeposit * ad.AffExRate) as MemDeposit_Aff,
				Sum(ad.MemWithdrawal * ad.AffExRate) as MemWithdrawal_Aff,
				Sum(ad.MemBonus * ad.AffExRate) as MemBonus_Aff,
				Sum(ad.MemAdjustment * ad.AffExRate) as MemAdjustment_Aff,
				Sum(ad.MemPSP * ad.AffExRate) as MemPSP_Aff,
				SUM(CASE WHEN @DrawFilter = 0 THEN
						ad.MemTurnover 
					ELSE
						ad.MemTurnoverNoDraw
					End * ad.AffExRate) as Turnover_Aff,
				Sum(CASE 
						WHEN ad.ProductID = @SportsbookId then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.AffExRate) as SportsBookTurnover_Aff,
				Sum(CASE 
						WHEN ad.ProductID = @NumberGame then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.AffExRate) as NumberGameTurnover_Aff,
				Sum(CASE 
						WHEN ad.ProductID = @LiveCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END * ad.AffExRate) as LiveCasinoTurnover_Aff,
				Sum(CASE 
						WHEN ad.ProductID = @RNGCasino then 
							(CASE WHEN @DrawFilter = 0 THEN
								ad.MemTurnover 
							ELSE
								ad.MemTurnoverNoDraw
							End)
						ELSE 0 
					END  * ad.AffExRate)as RNGCasinoTurnover_Aff,
				Sum(ad.MemWinlost * ad.AffExRate) as MemWinlost_Aff,
				-(Sum(CASE WHEN ad.ProductID = @SportsbookId then ad.MemWinlost ELSE 0 END  * ad.AffExRate)) as SportsBookWinlost_Aff,
				-(Sum(CASE WHEN ad.ProductID = @NumberGame then ad.MemWinlost ELSE 0 END  * ad.AffExRate)) as NumberGameWinlost_Aff,
				-(Sum(CASE WHEN ad.ProductID = @LiveCasino then ad.MemWinlost ELSE 0 END * ad.AffExRate)) as LiveCasinoWinlost_Aff,
				-(Sum(CASE WHEN ad.ProductID = @RNGCasino then ad.MemWinlost ELSE 0 END * ad.AffExRate)) as RNGCasinoWinlost_Aff,
				-(Sum(ad.MemWinlost * ad.AffExRate)) as Total_Aff
			From AffDaily ad with (nolock)
				inner JOIN #PlayerCurrencies as p ON ad.MemCurrency = p.CurrencyId
				inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
							as t on ad.AffId = t.AffId and DATEDIFF(m, ad.WinlostDate, t.MonthDate) = 0
			where Winlostdate between @FromDate and @ToDate
			Group by dateadd(m, datediff(m, 0, Winlostdate), 0)
					, p.Currency, p.CurrencyId
		) as tmp
		LEFT JOIN 
		(
			Select	dateadd(m, datediff(m, 0, Winlostdate), 0) as WinlostDate
					, COUNT(DISTINCT m.Username) as ActivePlayer
			From MemberDaily m WITH (NOLOCK) 
				inner JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, 'All', @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
							as t on m.AffId = t.AffId and DATEDIFF(m, m.WinlostDate, t.MonthDate) = 0
			where Winlostdate between @FromDate and @ToDate
				AND Turnover > 0
			GROUP  by dateadd(m, datediff(m, 0, Winlostdate), 0)
		) as m ON DATEDIFF(m, tmp.Winlostdate, m.WinlostDate) = 0	
	Group by tmp.Winlostdate, tmp.Currency, tmp.CurrencyId
	order by tmp.Winlostdate
End

drop TABLE #PlayerCurrencies

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CompanyWinlossReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CompanyWinlossReport] TO [vnteam] AS [dbo]