ALTER PROCEDURE [dbo].[AffAdmin_CommissionReport]
	@UserId int=0, 
	@AffName NVARCHAR(100) = NULL,
	@AffTypes varchar(100) = NULL,
	@CommGroups varchar(1000) = NULL,
	@PreferLanguages varchar(1000) = NULL,
	@Currencies varchar(100) = NULL,
	@GroupBy tinyint = 0,
	@FromDate smalldatetime = NULL,
	@ToDate smalldatetime = NULL,
	@DrawFilter tinyint = 0,
	@BaseCurrency tinyint = 0,
	@SortBy tinyint = 0,
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 0
AS
/*    
Task : Commission Report - Company View     
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffName: Affiliate username
• @AffTypes: List affilaite type
• @CommGroups: List Commission group
• @PreferLanguages: list preference language
• @Currencies: List currencies
• @GroupBy: by date or month (0: by Month; 1: by Affiliate)
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
	- 0: Commission
	- 1: Active Players
	- 2: Betcount
	- 3: Deposit
	- 4: Withdrawal
	- 5: Turnover
	- Note: Order by field must be converted to system exchange rate.
• @ExcludeTest: not include test accounts if true.
*/    

SET NOCOUNT ON 

IF(@FromDate > @ToDate)
	Return

DECLARE @CurrentDate datetime, @MaxCalculatedDate datetime, @PreviousMonth datetime
		, @AffectedRows int, @AffId int, @count int, @SystemExchangeId int
DECLARE @Amount money
		, @SportsbookAmount money, @SportsbookCommission decimal, @SportsbookQualifiedMember decimal
		, @NumberGameAmount money, @NumberGameCommission decimal, @NumberGameQualifiedMember decimal
		, @LiveCasinoAmount money, @LiveCasinoCommission decimal, @LiveCasinoQualifiedMember decimal
		, @RNGCasinoAmount money, @RNGCasinoCommission decimal, @RNGCasinoQualifiedMember decimal

--Reset todate to ending of date
SELECT	@ToDate = dbo.Aff_GetLastDayOfMonth(@ToDate)
		, @CurrentDate = CURRENT_TIMESTAMP
		, @PreviousMonth = DATEADD(m, -1, @CurrentDate)
		, @SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

Select @MaxCalculatedDate = isnull(max(WinlostDate), '2013-05-01') from AffCommission (nolock)

-- Get productid
Declare @SportsbookId int, @NumberGame int, @LiveCasino int, @RNGCasino int
Select	@SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
		, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
		, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

Declare @Cashback Table(AffId int,GroupID int, MonthDate datetime, Amount money, SysExRate float, DeductedPercentage decimal(9,8))

Declare @Result Table(AffId int, Status varchar(50), WinlostDate datetime, Username varchar(50), AffType varchar(50), Language nvarchar(255), ExchangeId int, Currency varchar(5), GroupID int, GroupName nvarchar(100)
					, Commission money, CommissionBase money, BetCount int, Deposit money, Withdrawal money, Turnover money, Winloss money
					, DepositBase money, WithdrawalBase money, TurnoverBase money, WinlossBase money
					, SportsbookActivePlayers int, SportsbookBetCount int, SportsbookTurnover money, SportsbookWinloss money, SportsbookQM int, SportsbookCommissionPercent decimal(9,8), SportsbookCommission money
					, SportsBookTurnoverBase money, SportsbookWinlossBase money, SportsbookCommissionBase money
					, NumberGameActivePlayers int, NumberGameBetCount int, NumberGameTurnover money, NumberGameWinloss money, NumberGameQM int, NumberGameCommissionPercent decimal(9,8), NumberGameCommission money
					, NumberGameTurnoverBase money, NumberGameWinlossBase money, NumberGameCommissionBase money
					, LiveCasinoActivePlayers int, LiveCasinoBetCount int, LiveCasinoTurnover money, LiveCasinoWinloss money, LiveCasinoQM int, LiveCasinoCommissionPercent decimal(9,8), LiveCasinoCommission money
					, LiveCasinoTurnoverBase money, LiveCasinoWinlossBase money, LiveCasinoCommissionBase money					
					, RNGCasinoActivePlayers int, RNGCasinoBetCount int, RNGCasinoTurnover money, RNGCasinoWinloss money, RNGCasinoQM int, RNGCasinoCommissionPercent decimal(9,8), RNGCasinoCommission money
					, RNGCasinoTurnoverBase money, RNGCasinoWinlossBase money, RNGCasinoCommissionBase money)

--For the old month that is calculated.
if(exists (select top(1) 1 from AffCommission(nolock) where winlostdate BETWEEN @FromDate AND @todate))
BEGIN

	INSERT INTO @Result(AffId, Status, WinlostDate, Username, AffType, Language, ExchangeId, Currency, GroupID, GroupName
					, Commission, CommissionBase, BetCount, Deposit, Withdrawal, Turnover, Winloss, DepositBase, WithdrawalBase, TurnoverBase, WinlossBase
					, SportsbookActivePlayers, SportsbookBetCount, SportsbookTurnover, SportsbookWinloss, SportsbookQM, SportsbookCommissionPercent, SportsbookCommission
					, SportsBookTurnoverBase, SportsbookWinlossBase, SportsbookCommissionBase
					, NumberGameActivePlayers, NumberGameBetCount, NumberGameTurnover, NumberGameWinloss, NumberGameQM, NumberGameCommissionPercent, NumberGameCommission
					, NumberGameTurnoverBase, NumberGameWinlossBase, NumberGameCommissionBase
					, LiveCasinoActivePlayers, LiveCasinoBetCount, LiveCasinoTurnover, LiveCasinoWinloss, LiveCasinoQM, LiveCasinoCommissionPercent, LiveCasinoCommission
					, LiveCasinoTurnoverBase, LiveCasinoWinlossBase, LiveCasinoCommissionBase
					, RNGCasinoActivePlayers, RNGCasinoBetCount, RNGCasinoTurnover, RNGCasinoWinloss, RNGCasinoQM, RNGCasinoCommissionPercent, RNGCasinoCommission
					, RNGCasinoTurnoverBase, RNGCasinoWinlossBase, RNGCasinoCommissionBase)
	SELECT	ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupId, cg.GroupName
			, Sum(ac.AffWinlost_aff) as Commission
			, Sum(ac.AffWinlost) as CommissionBase
			, Sum(CASE WHEN @DrawFilter = 1 THEN
						ac.MemberBetCountNoDraw 
					ELSE
						ac.MemberBetCount
					End) as BetCount
			, Sum(ac.MemberDeposit_Aff) as Deposit
			, Sum(ac.MemberWithdrawal_Aff) as Withdrawal
			, Sum(
					CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover_aff 
					ELSE
						ac.MemberTurnoverNoDraw_aff
					End) as Turnover
			, Sum(ac.MemberWinlost_aff) as Winloss
			, Sum(ac.MemberDeposit) as DepositBase
			, Sum(ac.MemberWithdrawal) as WithdrawalBase
			, Sum(CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover
					ELSE
						ac.MemberTurnoverDraw
					End) as TurnoverBase
			, Sum(ac.MemberWinlost) as WinlossBase
			--Sportbook
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.ActivePlayer ELSE 0 END) as SportsbookActivePlayer
			, Sum(Case WHEN ProductID = @SportsbookId THEN 
						CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
						End
				ELSE 0 END) as SportsbookBetCount
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
				ELSE 0 END) as SportsbookTurnover
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff ELSE 0 END) as SportsbookWinloss
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.QualifiedMember ELSE 0 END) as SportsbookQM
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.Commission ELSE 0 END) as SportsbookCommissionPercent
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff ELSE 0 END) as SportsbookCommission
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover 
						ELSE
							ac.MemberTurnoverDraw
						End)
				ELSE 0 END) as SportsbookTurnoverBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost ELSE 0 END) as SportsbookWinlossBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost ELSE 0 END) as SportsbookCommissionBase
							
			--NumberGame
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.ActivePlayer ELSE 0 END) as NumberGameActivePlayer
			, Sum(Case WHEN ProductID = @NumberGame THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as NumberGameBetCount
			, Sum(Case WHEN ProductID = @NumberGame THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as NumberGameTurnover
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff ELSE 0 END) as NumberGameWinloss
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.QualifiedMember ELSE 0 END) as NumberGameQM
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.Commission ELSE 0 END) as NumberGameCommissionPercent
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff ELSE 0 END) as NumberGameCommission
			, Sum(
				Case WHEN ProductID = @NumberGame THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as NumberGameTurnoverBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost ELSE 0 END) as NumberGameWinlossBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost ELSE 0 END) as NumberGameCommissionBase

			--LiveCasino
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.ActivePlayer ELSE 0 END) as LiveCasinoActivePlayer
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as LiveCasinoBetCount
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as LiveCasinoTurnover
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						ac.MemberWinlost_aff
					ELSE 0 END) as LiveCasinoWinloss
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.QualifiedMember ELSE 0 END) as LiveCasinoQM
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.Commission ELSE 0 END) as LiveCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff ELSE 0 END) as LiveCasinoCommission
			, Sum(
				Case WHEN ProductID = @LiveCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as LiveCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.MemberWinlost ELSE 0 END) as LiveCasinoWinlossBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost ELSE 0 END) as LiveCasinoCommissionBase
							
			--RNGCasino
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.ActivePlayer ELSE 0 END) as RNGCasinoActivePlayer
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as RNGCasinoBetCount
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as RNGCasinoTurnover
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff ELSE 0 END) as RNGCasinoWinloss
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.QualifiedMember ELSE 0 END) as RNGCasinoQM
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.Commission ELSE 0 END) as RNGCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff ELSE 0 END) as RNGCasinoCommission
			, Sum(
				Case WHEN ProductID = @RNGCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as RNGCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost ELSE 0 END) as RNGCasinoWinlossBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost ELSE 0 END) as RNGCasinoCommissionBase

	FROM AffCommission ac with (NOLOCK)
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
				as t on ac.AffId = t.AffId and DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN AffGroupHistory ag with (NOLOCK) on ac.AffId = ag.AffID and DATEDIFF(m, ac.WinlostDate, ag.MonthDate) = 0
		INNER JOIN CommGroupHistory cg with (NOLOCK) on ag.GroupID = cg.GroupID and ag.MonthDate = cg.MonthDate
	Where WinlostDate between @FromDate and @ToDate 
	Group by ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupID, cg.GroupName
End


-- For Current month

declare @month int, @year int
if(current_timestamp BETWEEN @FromDate AND @ToDate)
BEGIN
    select @month=month(current_timestamp),@year=year(current_timestamp)
	INSERT INTO @Result(AffId, Status, WinlostDate, Username, AffType, Language, ExchangeId, Currency, GroupID, GroupName
					, Commission, CommissionBase, BetCount, Deposit, Withdrawal, Turnover, Winloss, DepositBase, WithdrawalBase, TurnoverBase, WinlossBase
					, SportsbookActivePlayers, SportsbookBetCount, SportsbookTurnover, SportsbookWinloss, SportsbookQM, SportsbookCommissionPercent, SportsbookCommission
					, SportsBookTurnoverBase, SportsbookWinlossBase, SportsbookCommissionBase
					, NumberGameActivePlayers, NumberGameBetCount, NumberGameTurnover, NumberGameWinloss, NumberGameQM, NumberGameCommissionPercent, NumberGameCommission
					, NumberGameTurnoverBase, NumberGameWinlossBase, NumberGameCommissionBase
					, LiveCasinoActivePlayers, LiveCasinoBetCount, LiveCasinoTurnover, LiveCasinoWinloss, LiveCasinoQM, LiveCasinoCommissionPercent, LiveCasinoCommission
					, LiveCasinoTurnoverBase, LiveCasinoWinlossBase, LiveCasinoCommissionBase
					, RNGCasinoActivePlayers, RNGCasinoBetCount, RNGCasinoTurnover, RNGCasinoWinloss, RNGCasinoQM, RNGCasinoCommissionPercent, RNGCasinoCommission
					, RNGCasinoTurnoverBase, RNGCasinoWinlossBase, RNGCasinoCommissionBase)
	SELECT	ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupId, cg.GroupName
			, Sum(ac.AffWinlost_aff) as Commission
			, Sum(ac.AffWinlost) as CommissionBase
			, Sum(CASE WHEN @DrawFilter = 1 THEN
						ac.MemberBetCountNoDraw 
					ELSE
						ac.MemberBetCount
					End) as BetCount
			, Sum(ac.MemberDeposit_Aff) as Deposit
			, Sum(ac.MemberWithdrawal_Aff) as Withdrawal
			, Sum(
					CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover_aff 
					ELSE
						ac.MemberTurnoverNoDraw_aff
					End) as Turnover
			, Sum(ac.MemberWinlost_aff) as Winloss
			, Sum(ac.MemberDeposit) as DepositBase
			, Sum(ac.MemberWithdrawal) as WithdrawalBase
			, Sum(CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover
					ELSE
						ac.MemberTurnoverDraw
					End) as TurnoverBase
			, Sum(ac.MemberWinlost) as WinlossBase
			--Sportbook
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.ActivePlayer ELSE 0 END) as SportsbookActivePlayer
			, Sum(Case WHEN ProductID = @SportsbookId THEN 
						CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
						End
				ELSE 0 END) as SportsbookBetCount
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
				ELSE 0 END) as SportsbookTurnover
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff ELSE 0 END) as SportsbookWinloss
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.QualifiedMember ELSE 0 END) as SportsbookQM
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.Commission ELSE 0 END) as SportsbookCommissionPercent
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff ELSE 0 END) as SportsbookCommission
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover 
						ELSE
							ac.MemberTurnoverDraw
						End)
				ELSE 0 END) as SportsbookTurnoverBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost ELSE 0 END) as SportsbookWinlossBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost ELSE 0 END) as SportsbookCommissionBase
							
			--NumberGame
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.ActivePlayer ELSE 0 END) as NumberGameActivePlayer
			, Sum(Case WHEN ProductID = @NumberGame THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as NumberGameBetCount
			, Sum(Case WHEN ProductID = @NumberGame THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as NumberGameTurnover
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff ELSE 0 END) as NumberGameWinloss
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.QualifiedMember ELSE 0 END) as NumberGameQM
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.Commission ELSE 0 END) as NumberGameCommissionPercent
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff ELSE 0 END) as NumberGameCommission
			, Sum(
				Case WHEN ProductID = @NumberGame THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as NumberGameTurnoverBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost ELSE 0 END) as NumberGameWinlossBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost ELSE 0 END) as NumberGameCommissionBase

			--LiveCasino
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.ActivePlayer ELSE 0 END) as LiveCasinoActivePlayer
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as LiveCasinoBetCount
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as LiveCasinoTurnover
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						ac.MemberWinlost_aff
					ELSE 0 END) as LiveCasinoWinloss
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.QualifiedMember ELSE 0 END) as LiveCasinoQM
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.Commission ELSE 0 END) as LiveCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff ELSE 0 END) as LiveCasinoCommission
			, Sum(
				Case WHEN ProductID = @LiveCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as LiveCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.MemberWinlost ELSE 0 END) as LiveCasinoWinlossBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost ELSE 0 END) as LiveCasinoCommissionBase
							
			--RNGCasino
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.ActivePlayer ELSE 0 END) as RNGCasinoActivePlayer
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as RNGCasinoBetCount
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as RNGCasinoTurnover
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff ELSE 0 END) as RNGCasinoWinloss
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.QualifiedMember ELSE 0 END) as RNGCasinoQM
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.Commission ELSE 0 END) as RNGCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff ELSE 0 END) as RNGCasinoCommission
			, Sum(
				Case WHEN ProductID = @RNGCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as RNGCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost ELSE 0 END) as RNGCasinoWinlossBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost ELSE 0 END) as RNGCasinoCommissionBase

	FROM [dbo].[Aff_CommissionForMonthAll](@month,@year) ac 
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
				as t on ac.AffId = t.AffId and DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0		
		INNER JOIN CommGroup cg with (NOLOCK) on ac.GroupID = cg.GroupID
	Where ac.WinlostDate between @FromDate and @ToDate 
	Group by ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupID, cg.GroupName

    --return;
End



--Calculate commission Previous month that is not calculated yet
IF (DateDiff(m, @MaxCalculatedDate, @CurrentDate) = 2
	and  @PreviousMonth between @FromDate and @ToDate)
BEGIN
   select @month=month(@PreviousMonth),@year=year(@PreviousMonth)
   INSERT INTO @Result(AffId, Status, WinlostDate, Username, AffType, Language, ExchangeId, Currency, GroupID, GroupName
					, Commission, CommissionBase, BetCount, Deposit, Withdrawal, Turnover, Winloss, DepositBase, WithdrawalBase, TurnoverBase, WinlossBase
					, SportsbookActivePlayers, SportsbookBetCount, SportsbookTurnover, SportsbookWinloss, SportsbookQM, SportsbookCommissionPercent, SportsbookCommission
					, SportsBookTurnoverBase, SportsbookWinlossBase, SportsbookCommissionBase
					, NumberGameActivePlayers, NumberGameBetCount, NumberGameTurnover, NumberGameWinloss, NumberGameQM, NumberGameCommissionPercent, NumberGameCommission
					, NumberGameTurnoverBase, NumberGameWinlossBase, NumberGameCommissionBase
					, LiveCasinoActivePlayers, LiveCasinoBetCount, LiveCasinoTurnover, LiveCasinoWinloss, LiveCasinoQM, LiveCasinoCommissionPercent, LiveCasinoCommission
					, LiveCasinoTurnoverBase, LiveCasinoWinlossBase, LiveCasinoCommissionBase
					, RNGCasinoActivePlayers, RNGCasinoBetCount, RNGCasinoTurnover, RNGCasinoWinloss, RNGCasinoQM, RNGCasinoCommissionPercent, RNGCasinoCommission
					, RNGCasinoTurnoverBase, RNGCasinoWinlossBase, RNGCasinoCommissionBase)
	SELECT	ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupId, cg.GroupName
			, Sum(ac.AffWinlost_aff) as Commission
			, Sum(ac.AffWinlost) as CommissionBase
			, Sum(CASE WHEN @DrawFilter = 1 THEN
						ac.MemberBetCountNoDraw 
					ELSE
						ac.MemberBetCount
					End) as BetCount
			, Sum(ac.MemberDeposit_Aff) as Deposit
			, Sum(ac.MemberWithdrawal_Aff) as Withdrawal
			, Sum(
					CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover_aff 
					ELSE
						ac.MemberTurnoverNoDraw_aff
					End) as Turnover
			, Sum(ac.MemberWinlost_aff) as Winloss
			, Sum(ac.MemberDeposit) as DepositBase
			, Sum(ac.MemberWithdrawal) as WithdrawalBase
			, Sum(CASE WHEN @DrawFilter = 0 THEN
						ac.MemberTurnover
					ELSE
						ac.MemberTurnoverDraw
					End) as TurnoverBase
			, Sum(ac.MemberWinlost) as WinlossBase
			--Sportbook
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.ActivePlayer ELSE 0 END) as SportsbookActivePlayer
			, Sum(Case WHEN ProductID = @SportsbookId THEN 
						CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
						End
				ELSE 0 END) as SportsbookBetCount
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
				ELSE 0 END) as SportsbookTurnover
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff ELSE 0 END) as SportsbookWinloss
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.QualifiedMember ELSE 0 END) as SportsbookQM
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.Commission ELSE 0 END) as SportsbookCommissionPercent
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff ELSE 0 END) as SportsbookCommission
			, Sum(
				Case WHEN ProductID = @SportsbookId THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover 
						ELSE
							ac.MemberTurnoverDraw
						End)
				ELSE 0 END) as SportsbookTurnoverBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.MemberWinlost ELSE 0 END) as SportsbookWinlossBase
			, Sum(Case WHEN ProductID = @SportsbookId THEN ac.AffWinlost ELSE 0 END) as SportsbookCommissionBase
							
			--NumberGame
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.ActivePlayer ELSE 0 END) as NumberGameActivePlayer
			, Sum(Case WHEN ProductID = @NumberGame THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as NumberGameBetCount
			, Sum(Case WHEN ProductID = @NumberGame THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as NumberGameTurnover
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff ELSE 0 END) as NumberGameWinloss
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.QualifiedMember ELSE 0 END) as NumberGameQM
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.Commission ELSE 0 END) as NumberGameCommissionPercent
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff ELSE 0 END) as NumberGameCommission
			, Sum(
				Case WHEN ProductID = @NumberGame THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as NumberGameTurnoverBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.MemberWinlost ELSE 0 END) as NumberGameWinlossBase
			, Sum(Case WHEN ProductID = @NumberGame THEN ac.AffWinlost ELSE 0 END) as NumberGameCommissionBase

			--LiveCasino
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.ActivePlayer ELSE 0 END) as LiveCasinoActivePlayer
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as LiveCasinoBetCount
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as LiveCasinoTurnover
			, Sum(Case WHEN ProductID = @LiveCasino THEN 
						ac.MemberWinlost_aff
					ELSE 0 END) as LiveCasinoWinloss
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.QualifiedMember ELSE 0 END) as LiveCasinoQM
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.Commission ELSE 0 END) as LiveCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff ELSE 0 END) as LiveCasinoCommission
			, Sum(
				Case WHEN ProductID = @LiveCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as LiveCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.MemberWinlost ELSE 0 END) as LiveCasinoWinlossBase
			, Sum(Case WHEN ProductID = @LiveCasino THEN ac.AffWinlost ELSE 0 END) as LiveCasinoCommissionBase
							
			--RNGCasino
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.ActivePlayer ELSE 0 END) as RNGCasinoActivePlayer
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
					CASE WHEN @DrawFilter = 1 THEN
							ac.MemberBetCountNoDraw 
						ELSE
							ac.MemberBetCount
					End
				ELSE 0 END) as RNGCasinoBetCount
			, Sum(Case WHEN ProductID = @RNGCasino THEN 
						(CASE WHEN @DrawFilter = 0 THEN
							ac.MemberTurnover_aff 
						ELSE
							ac.MemberTurnoverNoDraw_aff
						End)
					ELSE 0 END) as RNGCasinoTurnover
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff ELSE 0 END) as RNGCasinoWinloss
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.QualifiedMember ELSE 0 END) as RNGCasinoQM
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.Commission ELSE 0 END) as RNGCasinoCommissionPercent
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff ELSE 0 END) as RNGCasinoCommission
			, Sum(
				Case WHEN ProductID = @RNGCasino THEN 
							(CASE WHEN @DrawFilter = 0 THEN
								ac.MemberTurnover 
							ELSE
								ac.MemberTurnoverDraw
							End)
				ELSE 0 END) as RNGCasinoTurnoverBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.MemberWinlost ELSE 0 END) as RNGCasinoWinlossBase
			, Sum(Case WHEN ProductID = @RNGCasino THEN ac.AffWinlost ELSE 0 END) as RNGCasinoCommissionBase

	FROM [dbo].[Aff_CommissionForMonthAll](@month,@year) ac 
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) 
				as t on ac.AffId = t.AffId and DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN AffGroupHistory ag with (NOLOCK) on ac.AffId = ag.AffID and DATEDIFF(m, ac.WinlostDate, ag.MonthDate) = 0
		INNER JOIN CommGroupHistory cg with (NOLOCK) on ag.GroupID = cg.GroupID and ag.MonthDate = cg.MonthDate
	Where WinlostDate between @FromDate and @ToDate 
	Group by ac.AffId, t.Status, WinlostDate, t.Username, t.AffType, t.Language, t.ExchangeId, t.Currency, cg.GroupID, cg.GroupName

END


-------Get Cashback data---------------------
insert into @Cashback (AffId, GroupId, MonthDate, Amount, SysExRate, DeductedPercentage)
Select a.AffId, d.GroupID, d.MonthDate, a.Amount, a.SysExRate, d.DeductedPercentage
From AffDeductionTransaction a with (nolock) 
inner join AffGroupHistory ai (nolock) on ai.affid=a.affid and datediff(m,a.MonthDate,ai.MonthDate)=0
inner JOIN DeductionSettingHistory d with (nolock) on a.DTypeID=d.DeductionID and ai.groupid=d.groupid and ai.MonthDate=d.MonthDate
inner join DeductionType c with (nolock) on a.DTypeID=c.DTypeID
Where c.[DTypeName]='Cashback'
and a.ProductID = 0 and datediff(m,a.MonthDate,current_timestamp)>0 
Union
Select a.AffId, d.GroupID, a.MonthDate, a.Amount, a.SysExRate, d.DeductedPercentage
From AffDeductionTransaction a with (nolock) 
inner join AffInfo ai with (nolock) on ai.affid=a.affid 
INNER JOIN DeductionSetting d with (nolock) on a.DTypeID=d.DeductionID and d.GroupID=ai.GroupID
inner join DeductionType c with (nolock) on d.DeductionID=c.DTypeID
Where c.[DTypeName]='Cashback'
	and a.ProductID = 0
	And datediff(m,a.MonthDate,current_timestamp)=0 

-------Return Data------------
IF(@GroupBy = 0) -- By Month
Begin
	Select r.AffId, r.WinlostDate, r.Status,  Username, AffType, Language, r.Currency, r.GroupID, r.GroupName
					, isnull(m.ActivePlayers, 0) as ActivePlayers, BetCount, (Commission -[dbo].[Aff_GetAffDeductionAll] (r.AffId, r.Winlostdate)) as Commission, Deposit, Withdrawal, Turnover, Winloss, ((Commission -[dbo].[Aff_GetAffDeductionAll] (r.AffId, r.Winlostdate)) *  [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null))  as CommissionBase, DepositBase, WithdrawalBase, TurnoverBase, WinlossBase					
					, isnull(m.SportsBookActivePlayers, 0) as SportsBookActivePlayers, SportsBookBetCount, SportsbookQM, SportsbookCommissionPercent, SportsBookTurnover, SportsbookWinloss, SportsbookCommission
					, SportsBookTurnoverBase, SportsbookWinlossBase, SportsbookCommissionBase
					, isnull(m.NumberGameActivePlayers, 0) as NumberGameActivePlayers, NumberGameBetCount, NumberGameQM, NumberGameCommissionPercent, NumberGameTurnover, NumberGameWinloss, NumberGameCommission
					, NumberGameTurnoverBase, NumberGameWinlossBase, NumberGameCommissionBase
					, isnull(m.LiveCasinoActivePlayers, 0) as LiveCasinoActivePlayers, LiveCasinoBetCount, LiveCasinoQM, LiveCasinoCommissionPercent, LiveCasinoTurnover, LiveCasinoWinloss, LiveCasinoCommission
					, LiveCasinoTurnoverBase, LiveCasinoWinlossBase, LiveCasinoCommissionBase
					, isnull(m.RNGCasinoActivePlayers, 0) as RNGCasinoActivePlayers, RNGCasinoBetCount, RNGCasinoQM, RNGCasinoCommissionPercent, RNGCasinoTurnover, RNGCasinoWinloss, RNGCasinoCommission
					, RNGCasinoTurnoverBase, RNGCasinoWinlossBase, RNGCasinoCommissionBase
					, isnull(c.DeductedPercentage, 0) as DeductedPercentage, isnull(c.Amount, 0) as Cashback, isnull(c.Amount *  [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null), 0) as CashbackBase
	From @Result as r
		LEFT JOIN @Cashback c on r.AffId = c.AffId and datediff(m, r.WinlostDate, c.MonthDate) = 0 and c.GroupId = r.GroupID
		LEFT JOIN 
		(
			Select	AffID
					, COUNT(distinct tmp.UserName) as ActivePlayers
					, SUM(Case WHEN ProductId = @SportsbookId THEN 1 ELSE 0 end) as SportsbookActivePlayers
					, SUM(Case WHEN ProductId = @NumberGame THEN 1 ELSE 0 end) as NumberGameActivePlayers
					, SUM(Case WHEN ProductId = @LiveCasino THEN 1 ELSE 0 end) as LiveCasinoActivePlayers
					, SUM(Case WHEN ProductId = @RNGCasino THEN 1 ELSE 0 end) as RNGCasinoActivePlayers
					, WinlostDate
			From 
				--Each users is unique counted in the month
				(SELECT DISTINCT AffId, dateadd(m, datediff(m, 0, Winlostdate), 0) as Winlostdate, ProductID, UserName
				From MemberDaily WITH (NOLOCK) 
				where Winlostdate between @FromDate and @ToDate
					AND Turnover > 0
				) as tmp
			GROUP  by AffID, Winlostdate
		) as m ON r.AffId = m.AffID and DATEDIFF(m, m.Winlostdate, r.WinlostDate) = 0	
	Order by (Case @SortBy 
				WHEN 0 THEN ((Commission -[dbo].[Aff_GetAffDeductionAll] (r.AffId, r.Winlostdate)) *  [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null))
				WHEN 1 THEN m.ActivePlayers
				WHEN 2 THEN r.BetCount
				WHEN 3 THEN r.DepositBase
				WHEN 4 THEN r.WithdrawalBase
				WHEN 5 THEN r.TurnoverBase
				WHEN 6 THEN r.WinlossBase
			End) desc, r.WinlostDate desc, r.AffId asc
End
Else
Begin--By Affiliate
	Select	r.AffId, r.Status, Username, AffType, Language, Currency
			, m.ActivePlayers as ActivePlayers
			, Sum(BetCount) as BetCount
			, Sum(ISNULL(Commission,0))- Sum([dbo].[Aff_GetAffDeductionAll] (r.AffId, Winlostdate)) as Commission
			, Sum(Deposit) as Deposit
			, Sum(Withdrawal) as Withdrawal
			, Sum(Turnover) as Turnover
			, Sum(Winloss) as Winloss
			, Sum(ISNULL(Commission,0))-Sum([dbo].[Aff_GetAffDeductionAll](r.AffId, Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null)  as CommissionBase
			, Sum(DepositBase) as DepositBase
			, Sum(WithdrawalBase) as WithdrawalBase
			, Sum(TurnoverBase) as TurnoverBase
			, Sum(WinlossBase) as WinlossBase

			--Sportbooks
			, Sum(isnull(m.SportsbookActivePlayers, 0)) as SportsbookActivePlayers
			, Sum(SportsbookBetCount) as SportsbookBetCount
			, Sum(SportsbookWinloss) as SportsbookWinloss
			, Sum(SportsbookCommission) as SportsbookCommission
			, Sum(SportsBookTurnoverBase) as SportsBookTurnoverBase
			, Sum(SportsbookWinlossBase) as SportsbookWinlossBase
			, Sum(SportsbookCommissionBase) as SportsbookCommissionBase

			--NumberGame
			, Sum(isnull(m.NumberGameActivePlayers, 0)) as NumberGameActivePlayers
			, Sum(NumberGameBetCount) as NumberGameBetCount
			, Sum(NumberGameTurnover) as NumberGameTurnover
			, Sum(NumberGameWinloss) as NumberGameWinloss
			, Sum(NumberGameCommission) as NumberGameCommission
			, Sum(NumberGameTurnoverBase) as NumberGameTurnoverBase
			, Sum(NumberGameWinlossBase) as NumberGameWinlossBase
			, Sum(NumberGameCommissionBase) as NumberGameCommissionBase

			--LiveCasino
			, Sum(isnull(m.LiveCasinoActivePlayers, 0)) as LiveCasinoActivePlayers
			, Sum(LiveCasinoBetCount) as LiveCasinoBetCount
			, Sum(LiveCasinoTurnover) as LiveCasinoTurnover
			, Sum(LiveCasinoWinloss) as LiveCasinoWinloss
			, Sum(LiveCasinoCommission) as LiveCasinoCommission
			, Sum(LiveCasinoTurnoverBase) as LiveCasinoTurnoverBase
			, Sum(LiveCasinoWinlossBase) as LiveCasinoWinlossBase
			, Sum(LiveCasinoCommissionBase) as LiveCasinoCommissionBase

			--RNGCasino
			, Sum(isnull(m.RNGCasinoActivePlayers, 0)) as RNGCasinoActivePlayers
			, Sum(RNGCasinoBetCount) as RNGCasinoBetCount
			, Sum(RNGCasinoTurnover) as RNGCasinoTurnover
			, Sum(RNGCasinoWinloss) as RNGCasinoWinloss
			, Sum(RNGCasinoCommission) as RNGCasinoCommission
			, Sum(RNGCasinoTurnoverBase) as RNGCasinoTurnoverBase
			, Sum(RNGCasinoWinlossBase) as RNGCasinoWinlossBase
			, Sum(RNGCasinoCommissionBase) as RNGCasinoCommissionBase

			--Cashback
			, Sum(isnull(c.DeductedPercentage, 0)) as DeductedPercentage
			, Sum(isnull(c.Amount, 0)) as Cashback
			, Sum(isnull(c.Amount , 0)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null) as CashbackBase

	From @Result as r
		LEFT JOIN @Cashback c on r.AffId = c.AffId and datediff(m, r.WinlostDate, c.MonthDate) = 0 and c.GroupId = r.GroupID
		
		LEFT JOIN 
		(
			Select	AffId
					, COUNT(distinct tmp.UserName) as ActivePlayers
					, SUM(Case WHEN ProductId = @SportsbookId THEN 1 ELSE 0 end) as SportsbookActivePlayers
					, SUM(Case WHEN ProductId = @NumberGame THEN 1 ELSE 0 end) as NumberGameActivePlayers
					, SUM(Case WHEN ProductId = @LiveCasino THEN 1 ELSE 0 end) as LiveCasinoActivePlayers
					, SUM(Case WHEN ProductId = @RNGCasino THEN 1 ELSE 0 end) as RNGCasinoActivePlayers
			From 
				--Each users is unique counted in Range Date
				(SELECT DISTINCT AffId, ProductID, UserName
				From MemberDaily WITH (NOLOCK) 
				where Winlostdate between @FromDate and @ToDate
					AND Turnover > 0
				) as tmp
			GROUP  by AffId
		) as m ON r.AffId = m.AffID	
	Group BY r.AffId, r.Status, Username, AffType, Language, Currency, m.ActivePlayers, r.ExchangeId
	Order by (Case @SortBy 
				WHEN 0 THEN Sum(ISNULL(Commission,0))-Sum([dbo].[Aff_GetAffDeductionAll](r.AffId, Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, null)
				WHEN 1 THEN m.ActivePlayers
				WHEN 2 THEN Sum(r.BetCount)
				WHEN 3 THEN Sum(r.DepositBase)
				WHEN 4 THEN Sum(r.WithdrawalBase)
				WHEN 5 THEN Sum(r.TurnoverBase) 
				WHEN 6 THEN Sum(r.WinlossBase) 
			END) desc, r.AffId asc
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommissionReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommissionReport] TO [vnteam] AS [dbo]