/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_StatisticsSel] 
	@AffID INT
	,@MonthDate SMALLDATETIME
	,@TotalQualifiedMembers INT OUTPUT
	,@TotalQualifiedCasino INT = 0 OUTPUT
	,@TotalQualifiedMembersHR INT OUTPUT
	,@TotalActivePlayer INT OUTPUT
	,@TotalPlayerDepUp INT OUTPUT
	,@TotalPlayer INT OUTPUT
	,@NewSignUpDep INT OUTPUT
	,@NewSignUp INT OUTPUT
	,@BalBroughtforward MONEY = 0 OUTPUT
	,@TotalDeposit MONEY OUTPUT
	,@TotalDepositUp MONEY OUTPUT
	,@TotalTurnover MONEY OUTPUT
	,@TotalTurnoverUp MONEY OUTPUT
	,@TotalWinlostUp MONEY OUTPUT
	,@TotalWinlost MONEY OUTPUT
	,@TotalUniqueClicks INT = 0 OUTPUT
	,@TotalClicks INT = 0 OUTPUT
	,@TotalUniqueClicksBySite INT = 0 OUTPUT -- Is PC / Laptop
	,@TotalClicksBySite INT = 0 OUTPUT -- Is PC / Laptop
	,@TotalUniqueClicksByMobile INT = 0 OUTPUT
	,@TotalClicksByMobile INT = 0 OUTPUT
AS

/*
	Created: 20090325@VinhTrinh
	Task : Get statistics for affiliate
	DB: DBAFF12BET.Affiliate_12BET
	Original : [Aff_CustomerSelStatistics]

	Revisions:
		- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).
		- 20090827@DungTong: Convert to new DB version
		- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"
		- 20101228@Henry: change bettype to new range
		- 20120507@Johnny: Get Casino qualified Active players
		- 20120606@Peter : Exclude waiting tickets 
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20140801@Bobby:  Update MemberClickStatistics
		- 20141218@Bobby: Update SS's bettype
		- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]

	Param's Explanation:
		• @AffID : Affiliate custid
		• @MonthDate : Date search(format:first day of the month).
		• @TotalActivePlayer : Get Active player in Month
		• @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system
		• @NewSignUpDep : Get new signups of the month
		• @TotalDeposit : total deposit money for month search
		• @TotalDepositUp money OUTPUT,--total deposit money up to now
		• @TotalTurnover money OUTPUT,--total turnover money up to now
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FromBeginMonth SMALLDATETIME
		,@ToNextMonth SMALLDATETIME

	SELECT @FromBeginMonth = DATEADD(month, DATEDIFF(month, 0, @MonthDate), 0)

	SELECT @ToNextMonth = DATEADD(month, 1, @FromBeginMonth)

	DECLARE @GroupId INT, @DeductedPercentage DECIMAL(9,8)

	SELECT @GroupId = GroupId FROM dbo.AffInfo WITH(NOLOCK) WHERE AffId = @AffId
	SELECT @DeductedPercentage = DeductedPercentage FROM dbo.DeductionSetting WITH(NOLOCK) WHERE GroupId = @GroupId AND DeductionID = 9
	
	IF @DeductedPercentage IS NULL
		SELECT @DeductedPercentage = 0
	
	DECLARE @MaxTransDate SMALLDATETIME
		,@FromDate SMALLDATETIME
		,@CurrentDate SMALLDATETIME
		,@PreviousDate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoID INT
		,@SPTurnover MONEY
		,@HRTurnover MONEY
		,@CasinoTurnover MONEY
		,@CasinoDeposit MONEY

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID = dbo.Aff_GetSportID('Casino')

	SELECT @SPTurnover = QMTurnOver
	FROM Sporttype WITH (NOLOCK)
	WHERE SportID = @SportsBookID

	SELECT @HRTurnover = QMTurnOver
	FROM Sporttype WITH (NOLOCK)
	WHERE SportID = @HorseRacingID

	SELECT @CasinoTurnover = QMTurnOver
		,@CasinoDeposit = QMDeposit
	FROM Sporttype WITH (NOLOCK)
	WHERE SportID = @CasinoID

	SELECT @CurrentDate = convert(VARCHAR(10), current_timestamp, 120)
		,@PreviousDate = dateadd(d, - 1, @CurrentDate)

	SELECT @MaxTransDate = max(WinlostDate)
	FROM AffCommission WITH (NOLOCK)

	SELECT @FromDate = dateadd(d, 1, @MaxTransDate)

	-- signup, FDM --
	SELECT @NewSignUpDep = COUNT(1)
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate >= @FromBeginMonth AND mi.CreatedDate < @ToNextMonth
		AND mi.AffId = @AffID
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.IBCCustID = mi.IBCCustID
				AND mr.RemovedDate >= @FromBeginMonth AND mr.RemovedDate < @ToNextMonth
		)

	SELECT @NewSignUp = COUNT(1)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH(NOLOCK)
	WHERE creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth
		AND AffiliateID = @AffID

	-- Total
	SELECT @TotalPlayerDepUp = COUNT(1)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId
		AND IBCCustID IS NOT NULL -- deposit

	SELECT @TotalPlayer = COUNT(1)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId
	-----

	DECLARE @TblStatistics AS TABLE (
		IBCCustID INT
		,Sporttype INT
		,QualifiedMember INT
		,Turnover MONEY
		,Deposit MONEY
		,Winlost MONEY
		,MonthDate SMALLDATETIME
		)

	INSERT INTO @TblStatistics
	SELECT 0
		,SportId
		,QualifiedMember
		,MemberTurnover
		,MemberDeposit
		,MemberWinlost
		,WinlostDate
	FROM AffCommission WITH (NOLOCK)
	WHERE AffId = @AffId
		AND WinlostDate <= @MaxTransDate
	
	UNION ALL
	SELECT b.IBCCustID
		,SportType
		,0
		,sum(isnull(TurnOver, 0) * isnull(AffExRate, 1)) AS Turnover
		,sum(isnull(Deposit, 0) * isnull(AffExRate, 1)) AS Deposit
		,sum(isnull(Winlost, 0) * isnull(AffExRate, 1)) AS Winlost
		,dateadd(mm, DATEDIFF(m, 0, b.WinlostDate), 0)
	FROM MemberDaily b WITH (NOLOCK)
		INNER JOIN MemberInfo ci WITH (NOLOCK)
		ON ci.IBCCustID = b.IBCCustID
	WHERE b.AffID = @AffID
		AND b.winlostdate BETWEEN @FromDate AND @PreviousDate --this condition use up index on winlostdate	
	GROUP BY b.IBCCustID
		,SportType
		,dateadd(mm, DATEDIFF(m, 0, b.winlostdate), 0)
	
	UNION ALL
	SELECT ci.IBCCustID
		,@SportsBookID
		,0
		,isnull(sum(CASE 
					WHEN bettype = 911 THEN 0
					WHEN (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN (CASE 
							WHEN Bettype IN (33, 43)
								AND liveawayscore = 0 THEN isnull(stake, 0) / 2 * e.Actualrate2
							ELSE isnull(stake, 0) * e.Actualrate2 END
							)
					ELSE 0
					END), 0) AS Turnover
		,isnull(sum(CASE bettype
					WHEN 22001 THEN (winlost - actual_stake) * e.Actualrate2
					ELSE 0
					END), 0) AS Deposit
		,isnull(sum(CASE 
					WHEN (
							bettype <= 999
							OR ( b.bettype BETWEEN 1301 AND 1399)
							OR bettype IN (21001, 21002, 21003, 21004, 21005, 22004, 22005)
							)
						AND ruben = 1 THEN (b.Winlost - b.Actual_Stake) * e.actualrate2
					ELSE 0
					END
					*
					CASE
					WHEN bettype = 911 THEN @DeductedPercentage
					ELSE 1
					END), 0) AS Winlost
		,convert(VARCHAR(10), current_timestamp, 120)
	FROM MemberInfo ci WITH (NOLOCK)
		INNER JOIN bodb02.dbo.bettrans b WITH (NOLOCK, INDEX = IX_custid_matchid_bettype)
		ON b.custid = ci.IBCCustID
		INNER JOIN Exchange_Current e WITH (NOLOCK)
		ON ci.currency = e.exchangeid
	WHERE b.winlostdate = @CurrentDate
		AND ci.AffID = @AffID
		AND ci.IsRemoved = 0
		AND (
			b.bettype <= 999
			OR ( b.bettype BETWEEN 1301 AND 1399)
			OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
		AND b.bettype NOT BETWEEN 31 AND 120 -- Not include Casino and Number Game and finance
		AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
		AND b.StatusID NOT IN (101, 102, 103, 121, 1)
	GROUP BY ci.IBCCustID

	--Calculate total up to now
	SELECT @TotalWinlostUp = Sum(Winlost)
		,@TotalTurnoverUp = Sum(Turnover)
		,@TotalDepositUp = Sum(CASE 
				WHEN Sporttype = @SportsBookID THEN Deposit
				ELSE 0
				END)
	FROM @TblStatistics

	--calculate month search
	SELECT @TotalWinlost = Sum(Winlost)
		,@TotalTurnover = Sum(Turnover)
		,@TotalDeposit = Sum(CASE 
				WHEN Sporttype = @SportsBookID THEN Deposit
				ELSE 0
				END)
	FROM @TblStatistics
	WHERE DATEDIFF(m, MonthDate, @MonthDate) = 0

	--Calculate for ActivePlayer and Qualified players
	IF @MonthDate > @MaxTransDate
	BEGIN
		SELECT @TotalActivePlayer = count(IBCCustID)
		FROM (
			SELECT DISTINCT IBCCustID --Get from table existed 
			FROM @TblStatistics
			WHERE DATEDIFF(m, MonthDate, @MonthDate) = 0
			GROUP BY IBCCustId
			HAVING sum(isnull(TurnOver, 0)) > 0
				OR sum(isnull(Deposit, 0)) > 0
			) a

		SELECT @TotalQualifiedMembers = count(IBCCustID)
		FROM (
			SELECT DISTINCT IBCCustID
			FROM @TblStatistics p
			WHERE datediff(m, MonthDate, @MonthDate) = 0
				AND Sporttype = @SportsBookID
			GROUP BY IBCCustID
			HAVING sum(Turnover) >= @SPTurnover
			) a

		SELECT @TotalQualifiedMembersHR = count(IBCCustID)
		FROM (
			SELECT DISTINCT IBCCustID
			FROM @TblStatistics p
			WHERE datediff(m, MonthDate, @MonthDate) = 0
				AND Sporttype = @HorseRacingID
			GROUP BY IBCCustID
			HAVING sum(Turnover) >= @HRTurnover
			) a

		SELECT @TotalQualifiedCasino = count(IBCCustID)
		FROM (
			SELECT DISTINCT IBCCustID
			FROM @TblStatistics p
			WHERE datediff(m, MonthDate, @MonthDate) = 0
				AND Sporttype = @CasinoID
			GROUP BY IBCCustID
			HAVING sum(Turnover) >= @CasinoTurnover
				AND SUM(Deposit) >= @CasinoDeposit
			) a
	END
	ELSE --Get Data in AffCommission
	BEGIN
		DECLARE @FirstDate SMALLDATETIME
			,@LastDate SMALLDATETIME

		SELECT @FirstDate = dateadd(m, datediff(m, 0, @MonthDate), 0)
			,@LastDate = dateadd(d, - 1, dateadd(m, datediff(m, 0, @MonthDate) + 1, 0))

		SELECT @TotalActivePlayer = count(*)
		FROM (
			SELECT DISTINCT IBCCustId --Get from Memberdaily
			FROM MemberDaily b WITH (NOLOCK)
			WHERE b.AffID = @AffID
				AND b.winlostdate BETWEEN @FirstDate AND @LastDate --this condition use up index on winlostdate	
			GROUP BY IBCCustId
			HAVING sum(isnull(TurnOver, 0)) > 0
				OR sum(isnull(Deposit, 0)) > 0
			) a

		SELECT @TotalQualifiedMembers = QualifiedMember
		FROM @TblStatistics
		WHERE datediff(m, MonthDate, @MonthDate) = 0
			AND Sporttype = @SportsBookID

		SELECT @TotalQualifiedMembersHR = QualifiedMember
		FROM @TblStatistics
		WHERE datediff(m, MonthDate, @MonthDate) = 0
			AND Sporttype = @HorseRacingID

		SELECT @TotalQualifiedCasino = QualifiedMember
		FROM @TblStatistics
		WHERE datediff(m, MonthDate, @MonthDate) = 0
			AND Sporttype = @CasinoID
	END

	--End Calculate for Month Search	
	--Get tracking information
	IF (DATEDIFF(MONTH, @MonthDate, CURRENT_TIMESTAMP) = 0)
	BEGIN
		SELECT @TotalUniqueClicks = SUM(UniqueClick), @TotalClicks = SUM(TotalClick)
		FROM (
			SELECT s.Date, COUNT(DISTINCT s.IP) AS UniqueClick, COUNT(1) AS TotalClick
			FROM ClickStatistics s(NOLOCK)
				INNER JOIN TrackingCode a(NOLOCK) ON a.TrackingID = s.TrackingID
			WHERE s.Date >= @MonthDate AND a.AffID = @AffID
			GROUP BY s.Date
		) AS A
	END
	ELSE
	BEGIN
		SELECT @TotalClicks = TotalClick
			,@TotalUniqueClicks = UniqueClick
		FROM ClickStatisticsSum(NOLOCK)
		WHERE AffID = @AffID
			AND TrackingID = 0
			AND IsForMonth = 1
			AND [date] >= @FromBeginMonth
			AND [date] < @ToNextMonth --and datediff(mm,@MonthDate,[date])=0
	END

	--Tracking statistics for new link
	;WITH CTE_Device AS (
		SELECT DeviceType, SUM(TotalClick) AS TotalClicks, SUM(UniqueClick) AS UniqueClicks
		FROM (
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT c.IP) AS UniqueClick
			FROM dbo.ClickStatistics1 c WITH (NOLOCK)
			WHERE
				c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.AffId = @AffId
			GROUP BY ISNULL(c.DeviceType, 0), c.Date

			UNION ALL
			SELECT
				ISNULL(c.DeviceType, 0) AS DeviceType,
				SUM(TotalClick) AS TotalClick,
				SUM(UniqueClick) AS UniqueClick
			FROM dbo.ClickStatistics1Sum c WITH (NOLOCK)
			WHERE
				c.Date >= @FromBeginMonth AND c.Date < @ToNextMonth
				AND c.AffId = @AffId
			GROUP BY ISNULL(c.DeviceType, 0), c.Date
		) AS A
		GROUP BY DeviceType
	)
	SELECT
		@TotalClicksBySite			= CASE WHEN DeviceType = 0 THEN ISNULL(TotalClicks, 0) ELSE @TotalClicksBySite END,
		@TotalUniqueClicksBySite	= CASE WHEN DeviceType = 0 THEN ISNULL(UniqueClicks, 0) ELSE @TotalUniqueClicksBySite END,
		@TotalClicksByMobile		= CASE WHEN DeviceType = 1 THEN ISNULL(TotalClicks, 0) ELSE @TotalClicksByMobile END,
		@TotalUniqueClicksByMobile	= CASE WHEN DeviceType = 1 THEN ISNULL(UniqueClicks, 0) ELSE @TotalUniqueClicksByMobile END
	FROM CTE_Device

	--get Balance broughtForward
	SELECT @BalBroughtforward = ISNULL(dbo.Aff_GetAffBalance(@AffID), 0)
END
GO