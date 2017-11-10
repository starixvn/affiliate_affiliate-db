/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_PlayersSelDetail] 
	@AffID INT
	,@sporttype TINYINT = 0
	,@MonthDate SMALLDATETIME = NULL
	,@PageSize INT = 200
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS

/*
	Created: @VietHoang
	Task: 
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20100511@Johnny: upgrade performance(paging first and then calculate member related)
		- 20101228@Henry: change bettype to new range
		- 20120606@Peter: Exclude waiting tickets
		- 20140403@Bobby:  exclude Keno product & other sports
		- 20141218@Bobby: Update SS's bettype
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20171109@Percy: Correct the way get active player [RedmineID: #86353]

	Param's Explanation:
		• @AffID : Affiliate custid
		• @MonthDate: Month search. If Month is null => get all month Else get just the specification month		
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @today SMALLDATETIME, @fdate SMALLDATETIME, @tdate SMALLDATETIME

	SELECT  @today = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	DECLARE @GroupId INT, @DeductedPercentage DECIMAL(9,8)

	SELECT  @GroupId = GroupId FROM dbo.AffInfo WITH(NOLOCK) WHERE AffId = @AffId
	SELECT  @DeductedPercentage = DeductedPercentage FROM dbo.DeductionSetting WITH(NOLOCK) WHERE GroupId = @GroupId AND DeductionID = 9
	
	IF @DeductedPercentage IS NULL
		SELECT @DeductedPercentage = 0

	IF @MonthDate IS NOT NULL
	BEGIN
		SELECT @fdate = DATEADD(mm, DATEDIFF(m, 0, @MonthDate), 0)

		SELECT @tdate = DATEADD(d, - 1, DATEADD(mm, DATEDIFF(m, 0, @MonthDate) + 1, 0))
	END

	DECLARE @SportsBookID INT
		,@HorseRacingID INT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	DECLARE @TmpCustId TABLE
	(
		IBCCustId INT
		,IBCUserName NVARCHAR(30)
		,username NVARCHAR(50)
		,Currency INT
		,RegisteredDate DATETIME
	)

	INSERT INTO @TmpCustId
	SELECT DISTINCT
		tmp.IBCCustId
		,mi.IBCUserName
		,mi.username
		,mi.Currency
		,mi.RegisteredDate
	FROM (
		SELECT b.CustId AS IBCCustID
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON b.custid = m.IBCCustID
		WHERE m.AffID = @AffID AND m.IsRemoved = 0
			AND (
				@MonthDate IS NULL
				OR DATEDIFF(m, @tdate, @today) = 0
			)
			AND b.winlostdate = @today
			AND (
				b.bettype <= 999
				OR ( b.bettype BETWEEN 1301 AND 1399)
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
			) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT IN (1000) --games
			AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		GROUP BY b.custid

		UNION ALL
		SELECT d.IBCCustID
		FROM MemberDaily d WITH (NOLOCK)
		WHERE (CASE 
				WHEN @MonthDate IS NULL THEN --for searching all month
					CASE WHEN d.winlostdate < @Today THEN 1 ELSE 0 END
				ELSE --for searching 1 month only
					CASE WHEN d.winlostdate BETWEEN @fdate AND @tdate THEN 1 ELSE 0 END
				END
			) = 1
			AND CASE WHEN @sporttype = 0 THEN d.sporttype ELSE @sporttype END = d.sporttype
			AND d.AffID = @AffID
			AND (
				turnover > 0
				OR deposit > 0
			)
		GROUP BY d.IBCCustID
	) tmp
		INNER JOIN dbo.MemberInfo mi WITH(NOLOCK) ON tmp.IBCCustID = mi.IBCCustID
	WHERE mi.AffID = @AffID

	--Paging
	SELECT @NRows = COUNT(*) FROM @TmpCustId

	IF ISNULL(@NRows, 0) <= 0
		RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #ListCustId (
		IBCCustID INT
		,IBCUserName NVARCHAR(30)
		,username NVARCHAR(50)
		,Currency INT
		,RegisteredDate DATETIME
		)

	INSERT INTO #ListCustId
	SELECT IBCCustID
		,IbcUsername
		,username
		,Currency
		,RegisteredDate
	FROM (
		SELECT TOP (@RowEnd) ROW_NUMBER() OVER (ORDER BY username) AS TheCount
			,IBCCustId
			,IbcUsername
			,username
			,Currency
			,RegisteredDate
		FROM @TmpCustId
		) x
	WHERE x.TheCount BETWEEN @RowStart AND @RowEnd

	SELECT IBCUserName
		,Username
		,RegisteredDate
		,isnull(sum(turnover), 0) AS turnover
		,isnull(sum(winlost), 0) AS winlost
		,isnull(sum(deposit), 0) AS deposit
		,isnull(sum(withdrawal), 0) AS withdrawal
		,isnull(sum(bonus), 0) AS bonus
		,isnull(sum(Adjustment), 0) AS Adjustment
		,isnull(sum(PSP), 0) AS PSP
	FROM (
		SELECT IBCUserName
			,m.username
			,m.RegisteredDate
			,isnull(sum(CASE 
						WHEN bettype = 911 THEN 0
						WHEN @SportType = 0
							AND (bettype < 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN (CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(stake, 0) / 2 * e.Actualrate2
								ELSE isnull(stake, 0) * e.Actualrate2 END
								)
						WHEN @SportType = @SportsBookID
							AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN stake * e.ActualRate2
						WHEN @SportType = @HorseRacingID
							AND bettype IN (31, 32, 33, 41, 42, 43) THEN (CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN isnull(stake, 0) / 2 * e.Actualrate2
								ELSE isnull(stake, 0) * e.Actualrate2 END
								)
						ELSE 0
						END), 0) AS turnover
			,isnull(sum(CASE 
						WHEN @SportType = 0
							AND (bettype < 999 OR ( b.bettype BETWEEN 1301 AND 1399))
							AND ruben = 1 THEN (winlost - actual_stake + playercomm) * e.ActualRate2
						WHEN @SportType = @SportsBookID
							AND ruben = 1
							AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - actual_stake + playercomm) * e.ActualRate2
						WHEN @SportType = @HorseRacingID
							AND ruben = 1
							AND bettype IN (31, 32, 33, 41, 42, 43) THEN (winlost - actual_stake + playercomm) * e.ActualRate2
						ELSE 0
						END
						*
						CASE
						WHEN bettype = 911 THEN @DeductedPercentage
						ELSE 1
						END), 0) AS WinLost
			,isnull(sum(CASE 
						WHEN @SportType < 2
							AND bettype = 22001 THEN (winlost - actual_stake) * e.ActualRate2
						ELSE 0
						END), 0) AS Deposit
			,isnull(sum(CASE 
						WHEN @SportType < 2
							AND bettype IN (22002, 22003) THEN (winlost - actual_stake) * e.ActualRate2
						ELSE 0
						END), 0) AS Withdrawal
			,isnull(sum(CASE 
						WHEN @SportType < 2
							AND bettype = 22004 THEN (winlost - actual_stake) * e.ActualRate2
						ELSE 0
						END), 0) AS Bonus
			,isnull(sum(CASE 
						WHEN @SportType < 2
							AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN 1
						ELSE 0
						END), 0) AS Adjustment
			,isnull(sum(CASE 
						WHEN @SportType < 2
							AND bettype = 22001 THEN (winlost - actual_stake) * e.ActualRate2
						ELSE 0
						END
						* e.DepositPercent
						+abs(CASE 
							WHEN @SportType < 2
								AND bettype IN (22002, 22003) THEN (winlost - actual_stake) * e.ActualRate2
							ELSE 0
							END)
							* e.WithdrawalPercent
						), 0) AS PSP
		FROM bodb02.dbo.bettrans b WITH (NOLOCK)
			INNER JOIN #ListCustId m WITH (NOLOCK) ON m.IBCCustID = b.custID
			INNER JOIN Exchange_Current e WITH (NOLOCK) ON m.Currency = e.Exchangeid
		WHERE (
				@MonthDate IS NULL
				OR DATEDIFF(m, @tdate, @today) = 0
			)
			AND b.winlostdate = @Today
			AND (
				b.bettype <= 999
				OR ( b.bettype BETWEEN 1301 AND 1399)
				OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT IN (1000) --games
			AND b.bettype NOT BETWEEN 1101 AND 1199 -- Live Casino
			AND b.bettype NOT BETWEEN 1201 AND 1299 --Virtual Sport	
			AND b.bettype NOT BETWEEN 1501 AND 1599 -- Keno  
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
					--and bettype not in (31,32,33,41,42,43)   
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
		--and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'  
		GROUP BY IBCUserName
			,m.username
			,m.RegisteredDate
		
		UNION ALL
		SELECT IBCUserName
			,m.username
			,m.RegisteredDate
			,isnull(sum(d.turnover * d.AffExRate), 0) AS turnover
			,isnull(sum(d.winlost * d.AffExRate), 0) AS winlost
			,isnull(sum(d.deposit * d.AffExRate), 0) AS deposit
			,isnull(sum(d.withdrawal * d.AffExRate), 0) AS withdrawal
			,isnull(sum(d.bonus * d.AffExRate), 0) AS bonus
			,isnull(sum(d.Adjustment * d.AffExRate), 0) AS Adjustment
			,isnull(sum(d.PSP * d.AffExRate), 0) AS PSP
		FROM MemberDaily d WITH (NOLOCK)
			INNER JOIN #ListCustId m WITH (NOLOCK) ON m.IbcCustid = d.IbcCustid
		WHERE (CASE WHEN @MonthDate IS NULL THEN --for searching all month  
					CASE WHEN d.winlostdate < @Today THEN 1 ELSE 0 END
				ELSE --for searching 1 month only  
					CASE WHEN d.winlostdate BETWEEN @fdate AND @tdate THEN 1 ELSE 0 END
				END
			) = 1
			AND CASE WHEN @sporttype = 0 THEN d.sporttype ELSE @sporttype END = d.sporttype
			AND d.AffID = @AffID
		GROUP BY IBCUserName
			,m.username
			,m.RegisteredDate
	) AS tmp
	GROUP BY IBCUserName
		,Username
		,RegisteredDate
	ORDER BY Username
END
GO