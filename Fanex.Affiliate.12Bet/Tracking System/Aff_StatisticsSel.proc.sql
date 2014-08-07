ALTER PROCEDURE [dbo].[Aff_StatisticsSel] 
	@AffID INT
	,@MonthDate SMALLDATETIME
	,@TotalQualifiedMembers INT OUTPUT
	,@TotalQualifiedCasino INT = 0 OUTPUT
	,@TotalQualifiedMembersHR INT OUTPUT
	,@TotalActivePlayer INT OUTPUT
	,@TotalPlayerDepUp INT OUTPUT
	,@NewSignUpDep INT OUTPUT
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
/*Created: 20090325@VinhTrinh
Task : Get statistics for affiliate
DB: DB052.Affiliate_12BET
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

	SELECT @NewSignUpDep = Count(1)
	FROM MemberInfo m WITH (NOLOCK)
	WHERE m.AffId = @AffId
		AND CreatedDate >= @FromBeginMonth
		AND CreatedDate < @ToNextMonth -- datediff(m, CreatedDate, @MonthDate) = 0
		AND m.IBCCustId NOT IN (
			SELECT IBCCustId
			FROM MemberRemoval WITH (NOLOCK)
			WHERE RemovedDate >= @FromBeginMonth
				AND RemovedDate < @ToNextMonth
			) --datediff(m, RemovedDate, @MonthDate) = 0	

	SELECT --If member is created and removed in the same month, he/she will not be counted.
		@TotalPlayerDepUp = Count(*)
	FROM MemberInfo m WITH (NOLOCK)
	WHERE m.AffId = @AffId
		AND IsRemoved = 0

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
		,sum((isnull(Winlost, 0)) * isnull(AffExRate, 1)) AS Winlost
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
		,CASE 
			WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
			ELSE @SportsBookID
			END
		,0
		,isnull(sum(CASE 
					WHEN bettype < 99 THEN (CASE 
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
							bettype < 99
							OR bettype IN (21001, 21002, 21003, 21004, 21005, 22004, 22005)
							)
						AND ruben = 1 THEN (b.Winlost - b.Actual_Stake) * e.actualrate2
					ELSE 0
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
			OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
		AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
		AND b.bettype NOT IN (1000) --games
		AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
		AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
		AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
				--and bettype not in (31,32,33,41,42,43)   
		AND b.StatusID NOT IN (101, 102, 103, 121, 1)
	--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
	GROUP BY ci.IBCCustID
		,CASE 
			WHEN bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
			ELSE @SportsBookID
			END

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
	IF (datediff(mm, @MonthDate, current_timestamp) = 0)
	BEGIN
		SELECT @TotalClicks = count(1)
		FROM ClickStatistics s(NOLOCK)
			INNER JOIN TrackingCode a(NOLOCK)
			ON a.TrackingID = s.TrackingID
				AND a.AffID = @AffID
		WHERE s.DATE >= @MonthDate

		SELECT @TotalUniqueClicks = count(DISTINCT s.IP)
		FROM ClickStatistics s(NOLOCK)
			INNER JOIN TrackingCode a(NOLOCK)
			ON a.TrackingID = s.TrackingID
				AND a.AffID = @AffID
		WHERE s.DATE >= @MonthDate
			--group by a.AffiliateID,month(s.Date),year(s.Date)
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
	DECLARE @ToDate SMALLDATETIME

	SELECT @ToDate = dateadd(d, - 1, dateadd(mm, 1, @MonthDate))

	SELECT @TotalClicksBySite = CASE when DeviceType = 0 then ISNULL(TotalClicks,0) else @TotalClicksBySite end
		,@TotalUniqueClicksBySite = CASE when DeviceType = 0 then UniqueClicks else @TotalUniqueClicksBySite end
		,@TotalClicksByMobile = CASE when DeviceType = 1 then TotalClicks else @TotalClicksByMobile end
		,@TotalUniqueClicksByMobile = CASE when DeviceType = 1 then UniqueClicks else @TotalUniqueClicksByMobile end
	FROM [dbo].[Aff_GetClickStatisticsNew_Func](@AffId, @MonthDate, @Todate)

	--get Balance broughtForward
	SELECT @BalBroughtforward = isnull(dbo.Aff_GetAffBalance(@AffID), 0)
END
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNetView] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_StatisticsSel] TO [vnteam] AS [dbo]