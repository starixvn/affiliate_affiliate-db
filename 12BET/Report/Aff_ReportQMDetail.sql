/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_ReportQMDetail] 
	@AffID INT
	,@Month INT
	,@Year INT
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS

/*
	Created: 20091213@Peter
	Task: Get List of Qualifying members report for one affiliate.
	DB: DBAFF12BET.Affiliate_12BET
	Original:

	Revisions:
		- 20110523@Henry: change bettype to new range
		- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20120606@Peter : Exclude waiting tickets
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]

	Param's Explanation:
	
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TblResult TABLE (
		IBCCustId INT PRIMARY KEY
		,SPTurnOver MONEY
		,HRTurnOver MONEY
		,CATurnover MONEY
		,CADeposit MONEY
		)
	DECLARE @MemList TABLE (
		IBCCustId INT
		,AffExRate FLOAT
		)

	INSERT INTO @MemList
	SELECT m.IBCCustId
		,e.ActualRate2
	FROM MemberInfo m WITH (NOLOCK)
		INNER JOIN Exchange_Current e WITH (NOLOCK) ON m.Currency = e.ExchangeId
	WHERE m.AffId = @AffId
		AND IsRemoved = 0

	--select * from @MemList
	DECLARE @FirstDay SMALLDATETIME
		,@LastDay SMALLDATETIME
		,@CurrDate SMALLDATETIME
		,@PrevCurrDate SMALLDATETIME
		,@tmpToDate SMALLDATETIME
		,@SportsBookID INT
		,@HorseRacingID INT
		,@CasinoID INT
		,@SPQMAmount MONEY
		,@HRQMAmount MONEY
		,@CAQMAmount MONEY
		,@CAQMDeposit MONEY

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')
		,@CasinoID = dbo.Aff_GetSportID('Casino')

	SELECT @SPQMAmount = QMTurnOver
	FROM SportType(NOLOCK)
	WHERE SportID = @SportsBookID

	SELECT @HRQMAmount = QMTurnOver
	FROM SportType(NOLOCK)
	WHERE SportID = @HorseRacingID

	SELECT @CAQMAmount = QMTurnOver
		,@CAQMDeposit = QMDeposit
	FROM SportType(NOLOCK)
	WHERE SportID = @CasinoID

	--Get First date and last date and current date in order to calculate turnover
	SELECT @CurrDate = convert(VARCHAR(10), current_timestamp, 120)
		,@PrevCurrDate = DATEADD(DAY, -1, @CurrDate)
		,@FirstDay = cast(cast(@Year AS VARCHAR(5)) + '-' + cast(@Month AS VARCHAR(5)) + '-' + '1' AS SMALLDATETIME)
		,@LastDay = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @FirstDay) + 1, 0))

	SELECT @tmpToDate = (CASE 
			WHEN @LastDay >= @PrevCurrDate THEN dateadd(d, - 1, @PrevCurrDate)
			ELSE @LastDay END
			)

	INSERT INTO @TblResult
	SELECT IBCCustId
		,Sum(SPTurnOver) AS SPTurnOver
		,Sum(HRTurnOver) AS HRTurnOver
		,Sum(CATurnOver) AS CATurnOver
		,Sum(CADeposit) AS CADeposit
	FROM (
		--Calculate for SP
		SELECT IBCCustID
			,--MemberDaily
			sum(TurnOver * AffExRate) AS SPTurnOver
			,0 AS HRTurnOver
			,0 AS CATurnOver
			,0 AS CADeposit
		FROM MemberDaily WITH (NOLOCK)
		WHERE SportType = @SportsBookID
			AND Winlostdate BETWEEN @FirstDay AND @tmpToDate
			AND AffID = @AffID
		GROUP BY IBCCustID
		
		UNION ALL
		SELECT m.IBCCustID
			,--Bettrans
			sum(CASE
				WHEN bettype = 911 THEN 0
				ELSE abs(b.Stake) * m.AffExRate
				END) AS SPTurnOver
			,0 AS HRTurnOver
			,0 AS CATurnOver
			,0 AS CADeposit
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN @MemList m ON b.CustId = m.IBCCustId
		WHERE @LastDay >= @PrevCurrDate
			AND Winlostdate BETWEEN @PrevCurrDate AND @CurrDate
			AND b.winlostdate >= @FirstDay
			AND (
				b.bettype <= 999
				OR ( b.bettype BETWEEN 1301 AND 1399)
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY IBCCustID
		
		UNION ALL
		--Calculate for HR	
		SELECT IBCCustID
			,0 AS SPTurnOver
			,sum(TurnOver * AffExRate) AS HRTurnOver
			,0 AS CATurnOver
			,0 AS CADeposit
		FROM MemberDaily WITH (NOLOCK)
		WHERE SportType = @HorseRacingID
			AND Winlostdate BETWEEN @FirstDay AND @tmpToDate
			AND AffID = @AffID
		GROUP BY IBCCustID
		
		UNION ALL
		SELECT m.IBCCustID
			,--Bettrans
			0 AS SPTurnOver
			,Sum(CASE 
					WHEN bettype IN (33, 43)
						AND liveawayscore = 0 THEN isnull(abs(stake), 0) / 2
					WHEN bettype = 911 THEN 0
					ELSE isnull(abs(stake), 0)
					END * isnull(m.AffExRate, 0)) AS HrTurnOver
			,0 AS CATurnOver
			,0 AS CADeposit
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN @MemList m ON b.CustId = m.IBCCustId
		WHERE @LastDay >= @PrevCurrDate
			AND Winlostdate BETWEEN @PrevCurrDate AND @CurrDate
			AND Winlostdate >= @FirstDay
			AND b.bettype IN (33, 43)
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY IBCCustID
		
		UNION ALL
		--Calculate for CA	
		SELECT IBCCustID
			,0 AS SPTurnOver
			,0 AS HRTurnOver
			,sum(TurnOver * AffExRate) AS CATurnOver
			,sum(Deposit * AffExRate) AS CADeposit
		FROM MemberDaily WITH (NOLOCK)
		WHERE SportType = @CasinoID
			AND Winlostdate BETWEEN @FirstDay AND @LastDay
			AND AffID = @AffID
		GROUP BY IBCCustID
		) tmp
	GROUP BY IBCCustId
	HAVING Sum(SPTurnOver) > 0
		OR Sum(HRTurnOver) > 0
		OR Sum(CATurnOver) > 0
		OR Sum(CADeposit) > 0

	SELECT @NRows = count(DISTINCT IBCCustID)
	FROM @TblResult

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT mi.username AS username
		,mi.IBCUserName
		,m.SPTurnOver
		,m.IsSPQM
		,m.HRTurnOver
		,m.IsHRQM
		,m.CATurnOver
		,m.IsCAQM
	FROM MemberInfo mi(NOLOCK)
		INNER JOIN (
		SELECT ROW_NUMBER() OVER (
				ORDER BY coalesce(SPTurnOver, HRTurnOver) DESC
					,IBCCustID
				) AS TheCount
			,IBCCustId
			,SPTurnOver
			,(CASE 
				WHEN isnull(SPTurnOver, 0) >= @SPQMAmount THEN 1
				ELSE 0 END
				) AS IsSPQM
			,HRTurnOver
			,(CASE 
				WHEN isnull(HRTurnOver, 0) >= @HRQMAmount THEN 1
				ELSE 0 END
				) AS IsHRQM
			,CATurnOver
			,(CASE 
				WHEN isnull(CATurnOver, 0) >= @CAQMAmount
					AND isnull(CADeposit, 0) >= @CAQMDeposit THEN 1
				ELSE 0 END
				) AS IsCAQM
		FROM @TblResult
		) m ON mi.IBCCustId = m.IBCCustId
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd
END
GO