ALTER PROCEDURE [dbo].[AffAdmin_CommissionReport] 
	@UserId				INT = 0
	,@AffName			NVARCHAR(100) = NULL
	,@AffTypes			VARCHAR(100) = NULL
	,@CommGroups		VARCHAR(1000) = NULL
	,@PreferLanguages	VARCHAR(1000) = NULL
	,@Currencies		VARCHAR(100) = NULL
	,@GroupBy			TINYINT = 0
	,@FromDate			SMALLDATETIME = NULL
	,@ToDate			SMALLDATETIME = NULL
	,@DrawFilter		TINYINT = 0
	,@BaseCurrency		TINYINT = 0
	,@SortBy			TINYINT = 0
	,@ExcludeTest		BIT = 1
	,@IsITAdmin			BIT = 0
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

IF (@FromDate > @ToDate) RETURN

DECLARE @CurrentDate DATETIME
	,@MaxCalculatedDate DATETIME
	,@PreviousMonth DATETIME
	,@AffectedRows INT
	,@AffId INT
	,@count INT
	,@SystemExchangeId INT
DECLARE @Amount MONEY
	,@SportsbookAmount MONEY
	,@SportsbookCommission DECIMAL
	,@SportsbookQualifiedMember DECIMAL
	,@NumberGameAmount MONEY
	,@NumberGameCommission DECIMAL
	,@NumberGameQualifiedMember DECIMAL
	,@LiveCasinoAmount MONEY
	,@LiveCasinoCommission DECIMAL
	,@LiveCasinoQualifiedMember DECIMAL
	,@RNGCasinoAmount MONEY
	,@RNGCasinoCommission DECIMAL
	,@RNGCasinoQualifiedMember DECIMAL

--Reset todate to ending of date
SELECT @ToDate = dbo.Aff_GetLastDayOfMonth(@ToDate)
	,@CurrentDate = CURRENT_TIMESTAMP
	,@PreviousMonth = DATEADD(m, - 1, @CurrentDate)
	,@SystemExchangeId = [dbo].[Aff_GetSystemCurrencyID]()

SELECT @MaxCalculatedDate = isnull(max(WinlostDate), '2013-05-01')
FROM AffCommission(NOLOCK)

-- Get productid
DECLARE @SportsbookId INT
	,@NumberGame INT
	,@LiveCasino INT
	,@RNGCasino INT

SELECT @SportsbookId = dbo.[Aff_GetProductID]('Sportsbook')
	,@NumberGame = dbo.[Aff_GetProductID]('Number Game')
	,@LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
	,@RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')

DECLARE @Cashback TABLE (
	AffId INT
	,GroupID INT
	,MonthDate DATETIME
	,Amount MONEY
	,SysExRate FLOAT
	,DeductedPercentage DECIMAL(9, 8)
	)
DECLARE @Result TABLE (
	AffId INT
	,STATUS VARCHAR(50)
	,WinlostDate DATETIME
	,Username VARCHAR(50)
	,AffType VARCHAR(50)
	,LANGUAGE NVARCHAR(255)
	,ExchangeId INT
	,Currency VARCHAR(5)
	,GroupID INT
	,GroupName NVARCHAR(100)
	,Commission MONEY
	,CommissionBase MONEY
	,BetCount INT
	,Deposit MONEY
	,Withdrawal MONEY
	,Turnover MONEY
	,Winloss MONEY
	,DepositBase MONEY
	,WithdrawalBase MONEY
	,TurnoverBase MONEY
	,WinlossBase MONEY
	,SportsbookActivePlayers INT
	,SportsbookBetCount INT
	,SportsbookTurnover MONEY
	,SportsbookWinloss MONEY
	,SportsbookQM INT
	,SportsbookCommissionPercent DECIMAL(9, 8)
	,SportsbookCommission MONEY
	,SportsBookTurnoverBase MONEY
	,SportsbookWinlossBase MONEY
	,SportsbookCommissionBase MONEY
	,NumberGameActivePlayers INT
	,NumberGameBetCount INT
	,NumberGameTurnover MONEY
	,NumberGameWinloss MONEY
	,NumberGameQM INT
	,NumberGameCommissionPercent DECIMAL(9, 8)
	,NumberGameCommission MONEY
	,NumberGameTurnoverBase MONEY
	,NumberGameWinlossBase MONEY
	,NumberGameCommissionBase MONEY
	,LiveCasinoActivePlayers INT
	,LiveCasinoBetCount INT
	,LiveCasinoTurnover MONEY
	,LiveCasinoWinloss MONEY
	,LiveCasinoQM INT
	,LiveCasinoCommissionPercent DECIMAL(9, 8)
	,LiveCasinoCommission MONEY
	,LiveCasinoTurnoverBase MONEY
	,LiveCasinoWinlossBase MONEY
	,LiveCasinoCommissionBase MONEY
	,RNGCasinoActivePlayers INT
	,RNGCasinoBetCount INT
	,RNGCasinoTurnover MONEY
	,RNGCasinoWinloss MONEY
	,RNGCasinoQM INT
	,RNGCasinoCommissionPercent DECIMAL(9, 8)
	,RNGCasinoCommission MONEY
	,RNGCasinoTurnoverBase MONEY
	,RNGCasinoWinlossBase MONEY
	,RNGCasinoCommissionBase MONEY
	)

--For the old month that is calculated.
IF (
		EXISTS (
			SELECT TOP (1) 1
			FROM AffCommission(NOLOCK)
			WHERE winlostdate BETWEEN @FromDate AND @todate
			)
		)
BEGIN
	INSERT INTO @Result (
		AffId
		,STATUS
		,WinlostDate
		,Username
		,AffType
		,LANGUAGE
		,ExchangeId
		,Currency
		,GroupID
		,GroupName
		,Commission
		,CommissionBase
		,BetCount
		,Deposit
		,Withdrawal
		,Turnover
		,Winloss
		,DepositBase
		,WithdrawalBase
		,TurnoverBase
		,WinlossBase
		,SportsbookActivePlayers
		,SportsbookBetCount
		,SportsbookTurnover
		,SportsbookWinloss
		,SportsbookQM
		,SportsbookCommissionPercent
		,SportsbookCommission
		,SportsBookTurnoverBase
		,SportsbookWinlossBase
		,SportsbookCommissionBase
		,NumberGameActivePlayers
		,NumberGameBetCount
		,NumberGameTurnover
		,NumberGameWinloss
		,NumberGameQM
		,NumberGameCommissionPercent
		,NumberGameCommission
		,NumberGameTurnoverBase
		,NumberGameWinlossBase
		,NumberGameCommissionBase
		,LiveCasinoActivePlayers
		,LiveCasinoBetCount
		,LiveCasinoTurnover
		,LiveCasinoWinloss
		,LiveCasinoQM
		,LiveCasinoCommissionPercent
		,LiveCasinoCommission
		,LiveCasinoTurnoverBase
		,LiveCasinoWinlossBase
		,LiveCasinoCommissionBase
		,RNGCasinoActivePlayers
		,RNGCasinoBetCount
		,RNGCasinoTurnover
		,RNGCasinoWinloss
		,RNGCasinoQM
		,RNGCasinoCommissionPercent
		,RNGCasinoCommission
		,RNGCasinoTurnoverBase
		,RNGCasinoWinlossBase
		,RNGCasinoCommissionBase
		)
	SELECT ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupId
		,cg.GroupName
		,Sum(ac.AffWinlost_aff) AS Commission
		,Sum(ac.AffWinlost) AS CommissionBase
		,Sum(CASE 
				WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
				ELSE ac.MemberBetCount
				END) AS BetCount
		,Sum(ac.MemberDeposit_Aff) AS Deposit
		,Sum(ac.MemberWithdrawal_Aff) AS Withdrawal
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
				ELSE ac.MemberTurnoverNoDraw_aff
				END) AS Turnover
		,Sum(ac.MemberWinlost_aff) AS Winloss
		,Sum(ac.MemberDeposit) AS DepositBase
		,Sum(ac.MemberWithdrawal) AS WithdrawalBase
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover
				ELSE ac.MemberTurnoverDraw
				END) AS TurnoverBase
		,Sum(ac.MemberWinlost) AS WinlossBase
		--Sportbook
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.ActivePlayer
				ELSE 0
				END) AS SportsbookActivePlayer
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS SportsbookBetCount
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS SportsbookTurnover
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS SportsbookWinloss
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.QualifiedMember
				ELSE 0
				END) AS SportsbookQM
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.Commission
				ELSE 0
				END) AS SportsbookCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff
				ELSE 0
				END) AS SportsbookCommission
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS SportsbookTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost
				ELSE 0
				END) AS SportsbookWinlossBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost
				ELSE 0
				END) AS SportsbookCommissionBase
		--NumberGame
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.ActivePlayer
				ELSE 0
				END) AS NumberGameActivePlayer
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS NumberGameBetCount
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS NumberGameTurnover
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS NumberGameWinloss
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.QualifiedMember
				ELSE 0
				END) AS NumberGameQM
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.Commission
				ELSE 0
				END) AS NumberGameCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff
				ELSE 0
				END) AS NumberGameCommission
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS NumberGameTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost
				ELSE 0
				END) AS NumberGameWinlossBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost
				ELSE 0
				END) AS NumberGameCommissionBase
		--LiveCasino
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS LiveCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS LiveCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS LiveCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS LiveCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS LiveCasinoQM
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.Commission
				ELSE 0
				END) AS LiveCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS LiveCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS LiveCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS LiveCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost
				ELSE 0
				END) AS LiveCasinoCommissionBase
		--RNGCasino
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS RNGCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS RNGCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS RNGCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS RNGCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS RNGCasinoQM
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.Commission
				ELSE 0
				END) AS RNGCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS RNGCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS RNGCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS RNGCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost
				ELSE 0
				END) AS RNGCasinoCommissionBase
	FROM AffCommission ac WITH (NOLOCK)
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
		ON ac.AffId = t.AffId
			AND DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN AffGroupHistory ag WITH (NOLOCK)
		ON ac.AffId = ag.AffID
			AND DATEDIFF(m, ac.WinlostDate, ag.MonthDate) = 0
		INNER JOIN CommGroupHistory cg WITH (NOLOCK)
		ON ag.GroupID = cg.GroupID
			AND ag.MonthDate = cg.MonthDate
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupID
		,cg.GroupName
END

-- For Current month
DECLARE @month INT
	,@year INT

IF (current_timestamp BETWEEN @FromDate AND @ToDate)
BEGIN
	SELECT @month = month(current_timestamp)
		,@year = year(current_timestamp)

	INSERT INTO @Result (
		AffId
		,STATUS
		,WinlostDate
		,Username
		,AffType
		,LANGUAGE
		,ExchangeId
		,Currency
		,GroupID
		,GroupName
		,Commission
		,CommissionBase
		,BetCount
		,Deposit
		,Withdrawal
		,Turnover
		,Winloss
		,DepositBase
		,WithdrawalBase
		,TurnoverBase
		,WinlossBase
		,SportsbookActivePlayers
		,SportsbookBetCount
		,SportsbookTurnover
		,SportsbookWinloss
		,SportsbookQM
		,SportsbookCommissionPercent
		,SportsbookCommission
		,SportsBookTurnoverBase
		,SportsbookWinlossBase
		,SportsbookCommissionBase
		,NumberGameActivePlayers
		,NumberGameBetCount
		,NumberGameTurnover
		,NumberGameWinloss
		,NumberGameQM
		,NumberGameCommissionPercent
		,NumberGameCommission
		,NumberGameTurnoverBase
		,NumberGameWinlossBase
		,NumberGameCommissionBase
		,LiveCasinoActivePlayers
		,LiveCasinoBetCount
		,LiveCasinoTurnover
		,LiveCasinoWinloss
		,LiveCasinoQM
		,LiveCasinoCommissionPercent
		,LiveCasinoCommission
		,LiveCasinoTurnoverBase
		,LiveCasinoWinlossBase
		,LiveCasinoCommissionBase
		,RNGCasinoActivePlayers
		,RNGCasinoBetCount
		,RNGCasinoTurnover
		,RNGCasinoWinloss
		,RNGCasinoQM
		,RNGCasinoCommissionPercent
		,RNGCasinoCommission
		,RNGCasinoTurnoverBase
		,RNGCasinoWinlossBase
		,RNGCasinoCommissionBase
		)
	SELECT ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupId
		,cg.GroupName
		,Sum(ac.AffWinlost_aff) AS Commission
		,Sum(ac.AffWinlost) AS CommissionBase
		,Sum(CASE 
				WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
				ELSE ac.MemberBetCount
				END) AS BetCount
		,Sum(ac.MemberDeposit_Aff) AS Deposit
		,Sum(ac.MemberWithdrawal_Aff) AS Withdrawal
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
				ELSE ac.MemberTurnoverNoDraw_aff
				END) AS Turnover
		,Sum(ac.MemberWinlost_aff) AS Winloss
		,Sum(ac.MemberDeposit) AS DepositBase
		,Sum(ac.MemberWithdrawal) AS WithdrawalBase
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover
				ELSE ac.MemberTurnoverDraw
				END) AS TurnoverBase
		,Sum(ac.MemberWinlost) AS WinlossBase
		--Sportbook
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.ActivePlayer
				ELSE 0
				END) AS SportsbookActivePlayer
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS SportsbookBetCount
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS SportsbookTurnover
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS SportsbookWinloss
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.QualifiedMember
				ELSE 0
				END) AS SportsbookQM
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.Commission
				ELSE 0
				END) AS SportsbookCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff
				ELSE 0
				END) AS SportsbookCommission
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS SportsbookTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost
				ELSE 0
				END) AS SportsbookWinlossBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost
				ELSE 0
				END) AS SportsbookCommissionBase
		--NumberGame
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.ActivePlayer
				ELSE 0
				END) AS NumberGameActivePlayer
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS NumberGameBetCount
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS NumberGameTurnover
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS NumberGameWinloss
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.QualifiedMember
				ELSE 0
				END) AS NumberGameQM
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.Commission
				ELSE 0
				END) AS NumberGameCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff
				ELSE 0
				END) AS NumberGameCommission
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS NumberGameTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost
				ELSE 0
				END) AS NumberGameWinlossBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost
				ELSE 0
				END) AS NumberGameCommissionBase
		--LiveCasino
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS LiveCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS LiveCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS LiveCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS LiveCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS LiveCasinoQM
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.Commission
				ELSE 0
				END) AS LiveCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS LiveCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS LiveCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS LiveCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost
				ELSE 0
				END) AS LiveCasinoCommissionBase
		--RNGCasino
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS RNGCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS RNGCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS RNGCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS RNGCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS RNGCasinoQM
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.Commission
				ELSE 0
				END) AS RNGCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS RNGCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS RNGCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS RNGCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost
				ELSE 0
				END) AS RNGCasinoCommissionBase
	FROM [dbo].[Aff_CommissionForMonthAll](@month, @year) ac
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
		ON ac.AffId = t.AffId
			AND DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN CommGroup cg WITH (NOLOCK)
		ON ac.GroupID = cg.GroupID
	WHERE ac.WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupID
		,cg.GroupName
		--return;
END

--Calculate commission Previous month that is not calculated yet
IF (
		DateDiff(m, @MaxCalculatedDate, @CurrentDate) = 2
		AND @PreviousMonth BETWEEN @FromDate AND @ToDate
		)
BEGIN
	SELECT @month = month(@PreviousMonth)
		,@year = year(@PreviousMonth)

	INSERT INTO @Result (
		AffId
		,STATUS
		,WinlostDate
		,Username
		,AffType
		,LANGUAGE
		,ExchangeId
		,Currency
		,GroupID
		,GroupName
		,Commission
		,CommissionBase
		,BetCount
		,Deposit
		,Withdrawal
		,Turnover
		,Winloss
		,DepositBase
		,WithdrawalBase
		,TurnoverBase
		,WinlossBase
		,SportsbookActivePlayers
		,SportsbookBetCount
		,SportsbookTurnover
		,SportsbookWinloss
		,SportsbookQM
		,SportsbookCommissionPercent
		,SportsbookCommission
		,SportsBookTurnoverBase
		,SportsbookWinlossBase
		,SportsbookCommissionBase
		,NumberGameActivePlayers
		,NumberGameBetCount
		,NumberGameTurnover
		,NumberGameWinloss
		,NumberGameQM
		,NumberGameCommissionPercent
		,NumberGameCommission
		,NumberGameTurnoverBase
		,NumberGameWinlossBase
		,NumberGameCommissionBase
		,LiveCasinoActivePlayers
		,LiveCasinoBetCount
		,LiveCasinoTurnover
		,LiveCasinoWinloss
		,LiveCasinoQM
		,LiveCasinoCommissionPercent
		,LiveCasinoCommission
		,LiveCasinoTurnoverBase
		,LiveCasinoWinlossBase
		,LiveCasinoCommissionBase
		,RNGCasinoActivePlayers
		,RNGCasinoBetCount
		,RNGCasinoTurnover
		,RNGCasinoWinloss
		,RNGCasinoQM
		,RNGCasinoCommissionPercent
		,RNGCasinoCommission
		,RNGCasinoTurnoverBase
		,RNGCasinoWinlossBase
		,RNGCasinoCommissionBase
		)
	SELECT ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupId
		,cg.GroupName
		,Sum(ac.AffWinlost_aff) AS Commission
		,Sum(ac.AffWinlost) AS CommissionBase
		,Sum(CASE 
				WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
				ELSE ac.MemberBetCount
				END) AS BetCount
		,Sum(ac.MemberDeposit_Aff) AS Deposit
		,Sum(ac.MemberWithdrawal_Aff) AS Withdrawal
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
				ELSE ac.MemberTurnoverNoDraw_aff
				END) AS Turnover
		,Sum(ac.MemberWinlost_aff) AS Winloss
		,Sum(ac.MemberDeposit) AS DepositBase
		,Sum(ac.MemberWithdrawal) AS WithdrawalBase
		,Sum(CASE 
				WHEN @DrawFilter = 0 THEN ac.MemberTurnover
				ELSE ac.MemberTurnoverDraw
				END) AS TurnoverBase
		,Sum(ac.MemberWinlost) AS WinlossBase
		--Sportbook
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.ActivePlayer
				ELSE 0
				END) AS SportsbookActivePlayer
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS SportsbookBetCount
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS SportsbookTurnover
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS SportsbookWinloss
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.QualifiedMember
				ELSE 0
				END) AS SportsbookQM
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.Commission
				ELSE 0
				END) AS SportsbookCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost_aff
				ELSE 0
				END) AS SportsbookCommission
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS SportsbookTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.MemberWinlost
				ELSE 0
				END) AS SportsbookWinlossBase
		,Sum(CASE 
				WHEN ProductID = @SportsbookId THEN ac.AffWinlost
				ELSE 0
				END) AS SportsbookCommissionBase
		--NumberGame
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.ActivePlayer
				ELSE 0
				END) AS NumberGameActivePlayer
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS NumberGameBetCount
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS NumberGameTurnover
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS NumberGameWinloss
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.QualifiedMember
				ELSE 0
				END) AS NumberGameQM
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.Commission
				ELSE 0
				END) AS NumberGameCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost_aff
				ELSE 0
				END) AS NumberGameCommission
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS NumberGameTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.MemberWinlost
				ELSE 0
				END) AS NumberGameWinlossBase
		,Sum(CASE 
				WHEN ProductID = @NumberGame THEN ac.AffWinlost
				ELSE 0
				END) AS NumberGameCommissionBase
		--LiveCasino
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS LiveCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS LiveCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS LiveCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS LiveCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS LiveCasinoQM
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.Commission
				ELSE 0
				END) AS LiveCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS LiveCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS LiveCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS LiveCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @LiveCasino THEN ac.AffWinlost
				ELSE 0
				END) AS LiveCasinoCommissionBase
		--RNGCasino
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.ActivePlayer
				ELSE 0
				END) AS RNGCasinoActivePlayer
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN CASE 
						WHEN @DrawFilter = 1 THEN ac.MemberBetCountNoDraw
						ELSE ac.MemberBetCount
						END
				ELSE 0
				END) AS RNGCasinoBetCount
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover_aff
						ELSE ac.MemberTurnoverNoDraw_aff END
						)
				ELSE 0
				END) AS RNGCasinoTurnover
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost_aff
				ELSE 0
				END) AS RNGCasinoWinloss
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.QualifiedMember
				ELSE 0
				END) AS RNGCasinoQM
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.Commission
				ELSE 0
				END) AS RNGCasinoCommissionPercent
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost_aff
				ELSE 0
				END) AS RNGCasinoCommission
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN (CASE 
						WHEN @DrawFilter = 0 THEN ac.MemberTurnover
						ELSE ac.MemberTurnoverDraw END
						)
				ELSE 0
				END) AS RNGCasinoTurnoverBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.MemberWinlost
				ELSE 0
				END) AS RNGCasinoWinlossBase
		,Sum(CASE 
				WHEN ProductID = @RNGCasino THEN ac.AffWinlost
				ELSE 0
				END) AS RNGCasinoCommissionBase
	FROM [dbo].[Aff_CommissionForMonthAll](@month, @year) ac
		INNER JOIN [dbo].[AffAdmin_AffiliateListForReport](@UserId, @AffName, @AffTypes, @CommGroups, @PreferLanguages, @Currencies, @ExcludeTest, @IsITAdmin, @FromDate, @ToDate) AS t
		ON ac.AffId = t.AffId
			AND DATEDIFF(m, ac.WinlostDate, t.MonthDate) = 0
		INNER JOIN AffGroupHistory ag WITH (NOLOCK)
		ON ac.AffId = ag.AffID
			AND DATEDIFF(m, ac.WinlostDate, ag.MonthDate) = 0
		INNER JOIN CommGroupHistory cg WITH (NOLOCK)
		ON ag.GroupID = cg.GroupID
			AND ag.MonthDate = cg.MonthDate
	WHERE WinlostDate BETWEEN @FromDate AND @ToDate
	GROUP BY ac.AffId
		,t.STATUS
		,WinlostDate
		,t.Username
		,t.AffType
		,t.LANGUAGE
		,t.ExchangeId
		,t.Currency
		,cg.GroupID
		,cg.GroupName
END

-------Get Cashback data---------------------
INSERT INTO @Cashback (
	AffId
	,GroupId
	,MonthDate
	,Amount
	,SysExRate
	,DeductedPercentage
	)
SELECT a.AffId
	,d.GroupID
	,d.MonthDate
	,a.Amount
	,a.SysExRate
	,d.DeductedPercentage
FROM AffDeductionTransaction a WITH (NOLOCK)
	INNER JOIN AffGroupHistory ai(NOLOCK)
	ON ai.affid = a.affid
		AND datediff(m, a.MonthDate, ai.MonthDate) = 0
	INNER JOIN DeductionSettingHistory d WITH (NOLOCK)
	ON a.DTypeID = d.DeductionID
		AND ai.groupid = d.groupid
		AND ai.MonthDate = d.MonthDate
	INNER JOIN DeductionType c WITH (NOLOCK)
	ON a.DTypeID = c.DTypeID
WHERE c.[DTypeName] = 'Cashback'
	AND a.ProductID = 0
	AND datediff(m, a.MonthDate, current_timestamp) > 0

UNION
SELECT a.AffId
	,d.GroupID
	,a.MonthDate
	,a.Amount
	,a.SysExRate
	,d.DeductedPercentage
FROM AffDeductionTransaction a WITH (NOLOCK)
	INNER JOIN AffInfo ai WITH (NOLOCK)
	ON ai.affid = a.affid
	INNER JOIN DeductionSetting d WITH (NOLOCK)
	ON a.DTypeID = d.DeductionID
		AND d.GroupID = ai.GroupID
	INNER JOIN DeductionType c WITH (NOLOCK)
	ON d.DeductionID = c.DTypeID
WHERE c.[DTypeName] = 'Cashback'
	AND a.ProductID = 0
	AND datediff(m, a.MonthDate, current_timestamp) = 0

-------Return Data------------
IF (@GroupBy = 0) -- By Month
BEGIN
	SELECT r.AffId
		,r.WinlostDate
		,r.STATUS
		,Username
		,AffType
		,LANGUAGE
		,r.Currency
		,r.GroupID
		,r.GroupName
		,isnull(m.ActivePlayers, 0) AS ActivePlayers
		,BetCount
		,(Commission - [dbo].[Aff_GetAffDeductionAll](r.AffId, r.Winlostdate)) AS Commission
		,Deposit
		,Withdrawal
		,Turnover
		,Winloss
		,((Commission - [dbo].[Aff_GetAffDeductionAll](r.AffId, r.Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId,  NULL)) AS CommissionBase
		,DepositBase
		,WithdrawalBase
		,TurnoverBase
		,WinlossBase
		,isnull(m.SportsBookActivePlayers, 0) AS SportsBookActivePlayers
		,SportsBookBetCount
		,SportsbookQM
		,SportsbookCommissionPercent
		,SportsBookTurnover
		,SportsbookWinloss
		,SportsbookCommission
		,SportsBookTurnoverBase
		,SportsbookWinlossBase
		,SportsbookCommissionBase
		,isnull(m.NumberGameActivePlayers, 0) AS NumberGameActivePlayers
		,NumberGameBetCount
		,NumberGameQM
		,NumberGameCommissionPercent
		,NumberGameTurnover
		,NumberGameWinloss
		,NumberGameCommission
		,NumberGameTurnoverBase
		,NumberGameWinlossBase
		,NumberGameCommissionBase
		,isnull(m.LiveCasinoActivePlayers, 0) AS LiveCasinoActivePlayers
		,LiveCasinoBetCount
		,LiveCasinoQM
		,LiveCasinoCommissionPercent
		,LiveCasinoTurnover
		,LiveCasinoWinloss
		,LiveCasinoCommission
		,LiveCasinoTurnoverBase
		,LiveCasinoWinlossBase
		,LiveCasinoCommissionBase
		,isnull(m.RNGCasinoActivePlayers, 0) AS RNGCasinoActivePlayers
		,RNGCasinoBetCount
		,RNGCasinoQM
		,RNGCasinoCommissionPercent
		,RNGCasinoTurnover
		,RNGCasinoWinloss
		,RNGCasinoCommission
		,RNGCasinoTurnoverBase
		,RNGCasinoWinlossBase
		,RNGCasinoCommissionBase
		,isnull(c.DeductedPercentage, 0) AS DeductedPercentage
		,isnull(c.Amount, 0) AS Cashback
		,isnull(c.Amount * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, NULL), 0) AS CashbackBase
	FROM @Result AS r
		LEFT JOIN @Cashback c
		ON r.AffId = c.AffId
			AND datediff(m, r.WinlostDate, c.MonthDate) = 0
			AND c.GroupId = r.GroupID
		LEFT JOIN (
		SELECT AffID
			,COUNT(DISTINCT tmp.UserName) AS ActivePlayers
			,SUM(CASE 
					WHEN ProductId = @SportsbookId THEN 1
					ELSE 0
					END) AS SportsbookActivePlayers
			,SUM(CASE 
					WHEN ProductId = @NumberGame THEN 1
					ELSE 0
					END) AS NumberGameActivePlayers
			,SUM(CASE 
					WHEN ProductId = @LiveCasino THEN 1
					ELSE 0
					END) AS LiveCasinoActivePlayers
			,SUM(CASE 
					WHEN ProductId = @RNGCasino THEN 1
					ELSE 0
					END) AS RNGCasinoActivePlayers
			,WinlostDate
		FROM
			--Each users is unique counted in the month
			(
			SELECT DISTINCT AffId
				,dateadd(m, datediff(m, 0, Winlostdate), 0) AS Winlostdate
				,ProductID
				,UserName
			FROM MemberDaily WITH (NOLOCK)
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
				AND Turnover > 0
			) AS tmp
		GROUP BY AffID
			,Winlostdate
		) AS m
		ON r.AffId = m.AffID
			AND DATEDIFF(m, m.Winlostdate, r.WinlostDate) = 0
	ORDER BY (CASE @SortBy
			WHEN 0 THEN ((Commission - [dbo].[Aff_GetAffDeductionAll](r.AffId, r.Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, NULL))
			WHEN 1 THEN m.ActivePlayers
			WHEN 2 THEN r.BetCount
			WHEN 3 THEN r.DepositBase
			WHEN 4 THEN r.WithdrawalBase
			WHEN 5 THEN r.TurnoverBase
			WHEN 6 THEN r.WinlossBase END
			) DESC
		,r.WinlostDate DESC
		,r.AffId ASC
END
ELSE
BEGIN --By Affiliate
	SELECT r.AffId
		,r.STATUS
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,m.ActivePlayers AS ActivePlayers
		,Sum(BetCount) AS BetCount
		,Sum(ISNULL(Commission, 0)) - Sum([dbo].[Aff_GetAffDeductionAll](r.AffId, Winlostdate)) AS Commission
		,Sum(Deposit) AS Deposit
		,Sum(Withdrawal) AS Withdrawal
		,Sum(Turnover) AS Turnover
		,Sum(Winloss) AS Winloss
		,Sum(ISNULL(Commission, 0)) - Sum([dbo].[Aff_GetAffDeductionAll](r.AffId, Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId,  NULL) AS CommissionBase
		,Sum(DepositBase) AS DepositBase
		,Sum(WithdrawalBase) AS WithdrawalBase
		,Sum(TurnoverBase) AS TurnoverBase
		,Sum(WinlossBase) AS WinlossBase
		--Sportbooks
		,Sum(isnull(m.SportsbookActivePlayers, 0)) AS SportsbookActivePlayers
		,Sum(SportsbookBetCount) AS SportsbookBetCount
		,Sum(SportsbookWinloss) AS SportsbookWinloss
		,Sum(SportsbookCommission) AS SportsbookCommission
		,Sum(SportsBookTurnoverBase) AS SportsBookTurnoverBase
		,Sum(SportsbookWinlossBase) AS SportsbookWinlossBase
		,Sum(SportsbookCommissionBase) AS SportsbookCommissionBase
		--NumberGame
		,Sum(isnull(m.NumberGameActivePlayers, 0)) AS NumberGameActivePlayers
		,Sum(NumberGameBetCount) AS NumberGameBetCount
		,Sum(NumberGameTurnover) AS NumberGameTurnover
		,Sum(NumberGameWinloss) AS NumberGameWinloss
		,Sum(NumberGameCommission) AS NumberGameCommission
		,Sum(NumberGameTurnoverBase) AS NumberGameTurnoverBase
		,Sum(NumberGameWinlossBase) AS NumberGameWinlossBase
		,Sum(NumberGameCommissionBase) AS NumberGameCommissionBase
		--LiveCasino
		,Sum(isnull(m.LiveCasinoActivePlayers, 0)) AS LiveCasinoActivePlayers
		,Sum(LiveCasinoBetCount) AS LiveCasinoBetCount
		,Sum(LiveCasinoTurnover) AS LiveCasinoTurnover
		,Sum(LiveCasinoWinloss) AS LiveCasinoWinloss
		,Sum(LiveCasinoCommission) AS LiveCasinoCommission
		,Sum(LiveCasinoTurnoverBase) AS LiveCasinoTurnoverBase
		,Sum(LiveCasinoWinlossBase) AS LiveCasinoWinlossBase
		,Sum(LiveCasinoCommissionBase) AS LiveCasinoCommissionBase
		--RNGCasino
		,Sum(isnull(m.RNGCasinoActivePlayers, 0)) AS RNGCasinoActivePlayers
		,Sum(RNGCasinoBetCount) AS RNGCasinoBetCount
		,Sum(RNGCasinoTurnover) AS RNGCasinoTurnover
		,Sum(RNGCasinoWinloss) AS RNGCasinoWinloss
		,Sum(RNGCasinoCommission) AS RNGCasinoCommission
		,Sum(RNGCasinoTurnoverBase) AS RNGCasinoTurnoverBase
		,Sum(RNGCasinoWinlossBase) AS RNGCasinoWinlossBase
		,Sum(RNGCasinoCommissionBase) AS RNGCasinoCommissionBase
		--Cashback
		,Sum(isnull(c.DeductedPercentage, 0)) AS DeductedPercentage
		,Sum(isnull(c.Amount, 0)) AS Cashback
		,Sum(isnull(c.Amount, 0)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, NULL) AS CashbackBase
	FROM @Result AS r
		LEFT JOIN @Cashback c
		ON r.AffId = c.AffId
			AND datediff(m, r.WinlostDate, c.MonthDate) = 0
			AND c.GroupId = r.GroupID
		LEFT JOIN (
		SELECT AffId
			,COUNT(DISTINCT tmp.UserName) AS ActivePlayers
			,SUM(CASE 
					WHEN ProductId = @SportsbookId THEN 1
					ELSE 0
					END) AS SportsbookActivePlayers
			,SUM(CASE 
					WHEN ProductId = @NumberGame THEN 1
					ELSE 0
					END) AS NumberGameActivePlayers
			,SUM(CASE 
					WHEN ProductId = @LiveCasino THEN 1
					ELSE 0
					END) AS LiveCasinoActivePlayers
			,SUM(CASE 
					WHEN ProductId = @RNGCasino THEN 1
					ELSE 0
					END) AS RNGCasinoActivePlayers
		FROM
			--Each users is unique counted in Range Date
			(
			SELECT DISTINCT AffId
				,ProductID
				,UserName
			FROM MemberDaily WITH (NOLOCK)
			WHERE Winlostdate BETWEEN @FromDate AND @ToDate
				AND Turnover > 0
			) AS tmp
		GROUP BY AffId
		) AS m
		ON r.AffId = m.AffID
	GROUP BY r.AffId
		,r.STATUS
		,Username
		,AffType
		,LANGUAGE
		,Currency
		,m.ActivePlayers
		,r.ExchangeId
	ORDER BY (CASE @SortBy
			WHEN 0 THEN Sum(ISNULL(Commission, 0)) - Sum([dbo].[Aff_GetAffDeductionAll](r.AffId, Winlostdate)) * [dbo].[Aff_GetExchangeRate](r.ExchangeID, @SystemExchangeId, NULL)
			WHEN 1 THEN m.ActivePlayers
			WHEN 2 THEN Sum(r.BetCount)
			WHEN 3 THEN Sum(r.DepositBase)
			WHEN 4 THEN Sum(r.WithdrawalBase)
			WHEN 5 THEN Sum(r.TurnoverBase)
			WHEN 6 THEN Sum(r.WinlossBase) END
			) DESC
		,r.AffId ASC
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommissionReport] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommissionReport] TO [vnteam] AS [dbo]
