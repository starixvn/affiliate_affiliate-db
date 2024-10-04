/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateReport] 
	@Username			NVARCHAR(50) = NULL
	,@FromDate 			DATE
	,@ToDate 			DATE
	,@IsGetAll 			BIT
	,@PreferredLanguage VARCHAR(11) = NULL
	,@AffType 			SMALLINT 	= NULL
	,@SportId 			SMALLINT 	= NULL
	,@PageIndex 		INT			= 1
	,@PageSize 			INT			= 50
	,@NRows				INT 		= 0 OUTPUT
	
AS

/*
	Created: @VinhTrinh
	Task : Get report by date for each affiliate.
	DB: DBAFF12BET.Affiliate_12BET
	Original: [Aff_AffiliateReport]

	Revisions:
		- 20101228@Henry: change bettype to new range
		- 20110420@Johnny: Filter by Sporttype and restore code to old bettype range
		- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		- 20140403@Bobby: exclude Keno product & other sports
		- 20141113@Bobby: Add columns (Tracking Rate (Unique/Total), New Trk. Rate (Unique/Total), Total Sign up, Total FDM, Active Member, Total QM)
		- 20141218@Bobby: Update SS's bettype
		- 20141223@Bobby: Hotfix#28059 - Filtering by PreferredLanguage
		- 20170214@Percy: Fix FDM/Signup Issue [RedmineID: #70507]
		- 20170411@Percy: Support search by Affiliate name [RedmineID: #74588]
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20170525@Percy: Integrate Cash Out [RedmineID: #74874]
		- 20180222@Percy: Change range of winlostdate when getting data [RedmineID: #90861]

	Param's Explanation:
		• @Fromdate Time search From
		• @Todate Time search To
		• @IsGetAll if getall = 1 => get data in all date
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurrDate 	DATE
		,@OldReportDate DATE
		,@TmpToDate 	DATE
		,@TmpFromDate 	DATE
		,@TmpOldWayDate DATE
		,@SportsBookID 	INT
		,@HorseRacingID INT
		,@PrevCurrDate 	DATE
	
	DECLARE @AffList	TABLE (AffId INT
		, UserName		VARCHAR(30)
		, GroupId		INT
		, RowIDX		INT IDENTITY(1,1))
	
	CREATE TABLE #AffPaging(
		AffId				INT
		,GroupId			INT
		,DeductedPercentage	DECIMAL (9,8) DEFAULT (0)
		,RowIDX			INT
	)
	
	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')
		,@HorseRacingID = dbo.Aff_GetSportID('Horse Racing')

	IF (
			@Fromdate > @Todate
			OR @Fromdate > CURRENT_TIMESTAMP
			) RETURN

	SELECT @CurrDate 	= CURRENT_TIMESTAMP
		,@PrevCurrDate	= DATEADD(D, -1, @CurrDate)
		,@FromDate		= DATEADD(M, DATEDIFF(M, 0, @FromDate), 0)
		,@ToDate 		= DATEADD(S, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, @ToDate)), 0))

	SELECT @OldReportDate = SValue
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_OldReportDate'

	IF (@OldReportDate IS NULL)
		SELECT @OldReportDate = '31 Oct 2009'

	IF (@IsGetAll = 1)
	BEGIN
		SELECT @FromDate = MIN(WinlostDate)
		FROM dbo.MemberDaily WITH (NOLOCK)

		SELECT @ToDate = CURRENT_TIMESTAMP

		SELECT @TmpFromDate = DATEADD(d, 1, @OldReportDate) --From date for new way calculate winlost

		SELECT @TmpToDate = DATEADD(d, - 1, @PrevCurrDate) --To date for new way calculate winlost

		SELECT @TmpOldWayDate = @OldReportDate
	END
	ELSE
	BEGIN
		SELECT @TmpFromDate = CASE 
				WHEN @FromDate <= @OldReportDate THEN DATEADD(d, 1, @OldReportDate)
				ELSE @FromDate
				END

		SELECT @TmpToDate = CASE 
				WHEN @ToDate >= @PrevCurrDate THEN DATEADD(d, - 1, @PrevCurrDate)
				ELSE @ToDate
				END

		SELECT @TmpOldWayDate = CASE 
				WHEN @ToDate >= @OldReportDate THEN @OldReportDate
				ELSE @ToDate
				END
	END
	
	CREATE TABLE #MemberBettrans (
		
		IBCCustId		INT
		,AffId			INT
		,SportType		INT
		,MemDeposit		MONEY
		,MemWithdrawal		MONEY
		,MemTurnover		MONEY
		,MemWinlost		MONEY
		,MemBonus			MONEY
		,MemPSP			MONEY
		,MemAdjustment		MONEY
		,ExRate2		FLOAT
	)
	
	CREATE TABLE #AffReport (
		AffId INT
		,Deposit		MONEY
		,Withdrawal		MONEY
		,Turnover		MONEY
		,Winlost		MONEY
		,Bonus			MONEY
		,PSP			MONEY
		,Adjustment		MONEY
		,AffAdjustment	MONEY
		,AffWithdrawal	MONEY
		,AffBF			MONEY
	)

	INSERT INTO @AffList(AffId, UserName, GroupId)
	SELECT ai.AffId
		,ai.Username
		,ai.GroupId
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN AffType at WITH (NOLOCK)
		ON ai.AffType = at.TypeId
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
		
	WHERE  ai.STATUS		= 'Approved'
		AND (@AffType IS NULL OR ai.AffType	= @AffType)
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage	= @PreferredLanguage)
		AND ai.UserName LIKE '%' + ISNULL(@Username, '') + '%'
	ORDER BY ai.AffId
	
	SELECT @NRows = @@ROWCOUNT
	
	IF (ISNULL(@NRows, 0) = 0) RETURN
	
	INSERT INTO	#AffPaging (AffId, GroupId, RowIDX)
	SELECT m.AffId
		,m.GroupId
		,m.RowIDX
	FROM @AffList m
	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY m.RowIDX

	UPDATE a
	SET a.DeductedPercentage = ds.DeductedPercentage
	FROM #AffPaging a
		INNER JOIN dbo.DeductionSetting ds ON a.GroupId = ds.GroupId AND ds.DeductionID = 9
	
	IF(@ToDate >= @PrevCurrDate)
	BEGIN
		INSERT INTO #MemberBettrans(
			IBCCustId
			,AffId
			,SportType
			,MemDeposit
			,MemWithdrawal
			,MemTurnover
			,MemWinlost
			,MemBonus
			,MemPSP
			,MemAdjustment
			,ExRate2
		)
		SELECT m.IBCCustID
			,m.AffID
			,CASE 
				WHEN b.bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
				ELSE @SportsBookID
			END
			,ISNULL(SUM(CASE 
						WHEN (
								@SportId IS NULL
								OR @SportId = @SportsBookID
							)
							AND bettype = 22001 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Deposit
			,ISNULL(SUM(CASE 
						WHEN (
								@SportId IS NULL
								OR @SportId = @SportsBookID
							)
							AND bettype IN (22002, 22003) THEN - (winlost - ABS(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Withdrawal
			,ISNULL(SUM(CASE 
						WHEN bettype = 911 THEN 0
						WHEN @SportId IS NULL
							AND (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN
								CASE
									WHEN Bettype IN (33, 43)
										AND liveawayscore = 0 THEN ABS(stake) / 2 * e.ActualRate2
									ELSE ABS(stake) * e.ActualRate2
									END
						WHEN @SportId = @SportsBookID
							AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
							AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN ABS(stake)* e.ActualRate2
						WHEN @SportId = @HorseRacingID
							AND bettype IN (31, 32, 33, 41, 42, 43) THEN
								CASE 
									WHEN Bettype IN (33, 43)
										AND liveawayscore = 0 THEN ABS(stake) / 2 * e.ActualRate2
									ELSE ABS(stake) * e.ActualRate2
									END
						ELSE 0
						END), 0) AS Turnover
			,ISNULL(SUM(CASE 
						WHEN @SportId IS NULL THEN
							CASE 
								WHEN (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND ruben = 1 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END
						WHEN @SportId = @SportsBookID THEN
							CASE 
								WHEN (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND ruben = 1
									AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END
						WHEN @SportId = @HorseRacingID THEN
							CASE 
								WHEN bettype IN (31, 32, 33, 41, 42, 43)
									AND ruben = 1 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END
						ELSE 0
						END
						*
						CASE
						WHEN Bettype = 911 THEN ISNULL(ml.DeductedPercentage, 0)
						ELSE 1
						END), 0) AS Winlost
			,ISNULL(SUM(CASE 
						WHEN (
								@SportId IS NULL
								OR @SportId = @SportsBookID
							)
							AND bettype = 22004 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Bonus
			,ISNULL(SUM(CASE 
						WHEN @SportId IS NULL OR @SportId = @SportsBookID THEN
							CASE bettype WHEN 22001 THEN (winlost - ABS(actual_stake)) * e.ActualRate2 ELSE 0 END * e.DepositPercent
							+ ABS(CASE WHEN bettype IN (22002, 22003) THEN (winlost - ABS(actual_stake)) * e.ActualRate2 ELSE 0 END) * e.WithdrawalPercent
						ELSE 0
						END), 0) AS PSP
			,ISNULL(SUM(CASE 
						WHEN @SportId IS NULL
							OR @SportId = @SportsBookID
							AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN (winlost - ABS(actual_stake)) * e.ActualRate2
						ELSE 0
						END), 0) AS Adjustment
			,e.ActualRate2
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK) ON b.CustId = m.IBCCustID	
			INNER JOIN #AffPaging ml ON m.AffId = ml.AffId
			INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON m.Currency = e.ExchangeId
		WHERE b.WinlostDate BETWEEN @PrevCurrDate AND @CurrDate
			AND b.WinlostDate >= @TmpFromDate
			AND m.IsRemoved = 0
			AND (
					b.bettype <= 999
					OR ( b.bettype BETWEEN 1301 AND 1399)
					OR b.bettype IN (21001, 21002, 21003, 21004, 21005, 22001, 22002, 22003, 22004, 22005)
				) --get SB only
			AND b.bettype NOT BETWEEN 31 AND 120 --Not include Casino and Number Game and finance
			AND b.bettype NOT BETWEEN 912 AND 914 -- Cash Out (keep 911 only)
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
			AND b.custid > 0
			
		GROUP BY m.IBCCustID
			,m.AffID
			,CASE 
				WHEN b.bettype IN (31, 32, 33, 41, 42, 43) THEN @HorseRacingID
				ELSE @SportsBookID
			END
			,e.ActualRate2
	END
	
	--Calculate winlost member in AffDaily
	INSERT INTO #AffReport(
		AffId
		,Deposit
		,Withdrawal
		,Turnover
		,Winlost
		,Bonus
		,PSP
		,Adjustment
		,AffAdjustment
		,AffWithdrawal
		,AffBF
	)
	SELECT ad.AffId
		,SUM(MemDeposit * ExRate2) AS Deposit
		,SUM(MemWithdrawal * ExRate2) AS Withdrawal
		,SUM(MemTurnover * ExRate2) AS Turnover
		,SUM(MemWinlost * ExRate2) AS Winlost
		,SUM(MemBonus * ExRate2) AS Bonus
		,SUM(MemPSP * ExRate2) AS PSP
		,SUM(MemAdjustment * ExRate2) AS Adjustment
		,0 AS AffAdjustment
		,0 AS AffWithdrawal
		,SUM(AffNetWinlost * ExRate2) AS AffBF
	FROM dbo.AffDaily ad WITH (NOLOCK)
		INNER JOIN #AffPaging m ON ad.AffID = m.AffId
	WHERE (@IsGetAll = 1 OR ad.WinlostDate BETWEEN @FromDate AND @ToDate)
		AND ISNULL(@SportId, SportId) = SportId
		AND (
			(SportId = 1 AND ad.WinlostDate <= @TmpToDate)
			OR SportId <> 1
		)
	GROUP BY ad.AffID

	--Get winlost member in Bettrans table
	IF(@ToDate >= @PrevCurrDate)
	BEGIN
		INSERT INTO #AffReport(
			AffId
			,Deposit
			,Withdrawal
			,Turnover
			,Winlost
			,Bonus
			,PSP
			,Adjustment
			,AffAdjustment
			,AffWithdrawal
			,AffBF
		)
		SELECT md.AffId
			,SUM(MemDeposit * ExRate2) AS Deposit
			,SUM(MemWithdrawal * ExRate2) AS Withdrawal
			,SUM(MemTurnover * ExRate2) AS Turnover
			,SUM(MemWinlost * ExRate2) AS Winlost
			,SUM(MemBonus * ExRate2) AS Bonus
			,SUM(MemPSP * ExRate2) AS PSP
			,SUM(MemAdjustment * ExRate2) AS Adjustment
			,0 AS AffAdjustment
			,0 AS AffWithdrawal
			,0 AS AffBF
		FROM #MemberBettrans md
		GROUP BY md.AffId
	END

	--Get Aff Adjusment and Aff Widthrawal
	INSERT INTO #AffReport(
		AffId
		,Deposit
		,Withdrawal
		,Turnover
		,Winlost
		,Bonus
		,PSP
		,Adjustment
		,AffAdjustment
		,AffWithdrawal
		,AffBF
	)
	SELECT a.AffId
		,0 AS Deposit
		,0 AS Withdrawal
		,0 AS Turnover
		,0 AS Winlost
		,0 AS Bonus
		,0 AS PSP
		,0 AS Adjustment
		,SUM(CASE 
				WHEN Transtype = 203 THEN Amount
				ELSE 0
				END) AS AffAdjustment
		,SUM(CASE 
				WHEN Transtype = 202 THEN ABS(Amount)
				ELSE 0
				END) AS AffWithdrawal
		,0 AS AffBF
	FROM dbo.AffTrans a WITH (NOLOCK)
		INNER JOIN #AffPaging m ON a.AffId = m.AffId
	WHERE (@IsGetAll = 1 OR a.TransDate BETWEEN @FromDate AND @ToDate)
		AND a.Transtype IN (202, 203)
		AND a.STATUS IN ('Pending', 'Approved', 'Completed')
	GROUP BY a.AffId

	DECLARE @CurrMonth			DATE
		, @MaxCalculatedDate	DATE

	SET @CurrMonth = DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0)

	SELECT @MaxCalculatedDate = MAX(ac.WinlostDate)
	FROM dbo.AffCommission ac WITH(NOLOCK)
					
	-- TotalClick, UniqueClick, Signup, FDM --
	CREATE TABLE #OldTracking (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)
	CREATE TABLE #NewTracking (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

	DECLARE @MaxSumDate SMALLDATETIME, @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME
	SELECT  @MaxSumDate = MAX(Date) FROM dbo.ClickStatisticsSum WITH(NOLOCK)

		/* Old */
		-- TotalClick, UniqueClick --
	IF @FromDate < @MaxSumDate
	BEGIN
		IF DAY(@FromDate) = 1
		BEGIN
			SELECT @tempFromDate = @FromDate
		END
		ELSE
		BEGIN
			SELECT @tempFromDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @FromDate), 0) -- the first day of next month
		END

		IF DATEADD(DAY, 1, @ToDate) > @MaxSumDate
		BEGIN
			SELECT @tempToDate = @MaxSumDate
		END
		ELSE
		BEGIN
			IF DAY(DATEADD(DAY, 2, @ToDate)) = 1
			BEGIN
				SELECT @tempToDate = @ToDate
			END
			ELSE
			BEGIN
				SELECT @tempToDate = DATEADD(DAY, 1, DATEADD(MONTH, DATEDIFF(MONTH, -1, @ToDate), -1)) -- the last day of previous month
			END
		END
		
		INSERT INTO #OldTracking
		SELECT
			c.AffID,
			SUM(c.TotalClick),
			SUM(c.UniqueClick),
			0 AS Signup,
			0 AS FDM
		FROM dbo.ClickStatisticsSum c WITH(NOLOCK)
		WHERE Date >= @tempFromDate AND Date < @tempToDate
			AND IsForMonth = 1
			AND TrackingID = 0 -- sum for months
			AND EXISTS (SELECT 1 FROM #AffPaging a WHERE a.AffId = c.AffID)
		GROUP BY c.AffID

		IF @FromDate < @tempFromDate
		BEGIN
			INSERT INTO #OldTracking
			SELECT
				AffID,
				SUM(TotalClick),
				SUM(UniqueClick),
				0 AS Signup,
				0 AS FDM
			FROM (
				SELECT
					t.AffID,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT s.IP) AS UniqueClick
				FROM dbo.ClickStatistics s WITH(NOLOCK)
					INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
				WHERE s.Date >= @FromDate AND s.Date < @tempToDate
					AND EXISTS (SELECT 1 FROM #AffPaging a WHERE a.AffId = t.AffID)
				GROUP BY t.AffID, s.Date
			) A
			GROUP BY AffID
		END

		IF @tempToDate < @ToDate
		BEGIN
			INSERT INTO #OldTracking
			SELECT
				AffID,
				SUM(TotalClick),
				SUM(UniqueClick),
				0 AS Signup,
				0 AS FDM
			FROM (
				SELECT
					t.AffID,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT s.IP) AS UniqueClick
				FROM dbo.ClickStatistics s WITH(NOLOCK)
					INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
				WHERE s.Date >= @tempToDate AND s.Date < DATEADD(DAY, 1, @ToDate)
					AND EXISTS (SELECT 1 FROM #AffPaging a WHERE a.AffId = t.AffID)
				GROUP BY t.AffID, s.Date
			) A
			GROUP BY AffID
		END
	END
	ELSE
	BEGIN
		INSERT INTO #OldTracking
		SELECT
			AffID,
			SUM(TotalClick),
			SUM(UniqueClick),
			0 AS Signup,
			0 AS FDM
		FROM (
			SELECT
				t.AffID,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
				INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
			WHERE s.Date >= @FromDate AND s.Date < DATEADD(DAY, 1, @ToDate)
				AND EXISTS (SELECT 1 FROM #AffPaging a WHERE a.AffId = t.AffID)
			GROUP BY t.AffID, s.Date
		) A
		GROUP BY AffID
	END
			
		-- Signup, FDM --
	INSERT INTO #OldTracking
	SELECT
		mi.AffID	AS AffID,
		0			AS TotalClick,
		0			AS UniqueClick,
		0			AS Signup,
		COUNT(1)	AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE mi.AffID = a.AffId)
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.IBCCustID = mi.IBCCustID
				AND mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
		)
	GROUP BY mi.AffID

	INSERT INTO #OldTracking
	SELECT
		AffiliateID	AS AffID,
		0			AS TotalClick,
		0			AS UniqueClick,
		COUNT(1)	AS Signup,
		0			AS FDM
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer md WITH (NOLOCK)
	WHERE creatdate >= @FromDate AND creatdate < DATEADD(DAY, 1, @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE md.AffiliateID = a.AffId)
	GROUP BY AffiliateID

		-- TotalClick, UniqueClick --
	INSERT INTO #NewTracking
	SELECT
		c.AffID,
		COUNT(1) AS TotalClick,
		COUNT(DISTINCT c.IP) AS UniqueClick,
		0 AS Signup,
		0 AS FDM
	FROM dbo.ClickStatistics1 c WITH (NOLOCK)
	WHERE
		c.Date >= @FromDate AND c.Date < DATEADD(DAY, 1, @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE c.AffId = a.AffId)
	GROUP BY c.AffID, c.Date

	INSERT INTO #NewTracking
	SELECT
		c.AffID,
		SUM(TotalClick) AS TotalClick,
		SUM(UniqueClick) AS UniqueClick,
		0 AS Signup,
		0 AS FDM
	FROM dbo.ClickStatistics1Sum c WITH (NOLOCK)
	WHERE
		(@IsGetAll = 1 OR c.Date >= @FromDate AND c.Date < DATEADD(DAY, 1, @ToDate))
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE c.AffId = a.AffId)
	GROUP BY c.AffID, c.Date
	
	;WITH OldTracking (AffId, TotalClick, UniqueClick)
	AS (
		SELECT AffId, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick
		FROM #OldTracking
		GROUP BY AffId
		HAVING SUM(ISNULL(TotalClick, 0)) >= 0 OR SUM(ISNULL(UniqueClick, 0)) >= 0
	)
	,NewTracking (AffId, TotalClick, UniqueClick)
	AS (
		SELECT AffId, SUM(ISNULL(TotalClick, 0)) AS TotalClick, SUM(ISNULL(UniqueClick, 0)) AS UniqueClick
		FROM #NewTracking
		GROUP BY AffId
	)
	,MemberStats (AffId, Signups, FDMs)
	AS (
		SELECT AffId, SUM(Signup) AS Signups, SUM(FDM) AS FDMs
		FROM #OldTracking
		GROUP BY AffId
	)
	,ActiveMember (AffId, TotalAM)
	AS (
		--select 0, 0
		SELECT t.AffId
			, SUM(Total)
		FROM (
			SELECT t1.AffId
				,t1.MonthDate
				,COUNT(DISTINCT t1.IBCCustID) AS Total
			FROM (
				SELECT md.AffId
					, md.IBCCustID
					, DATEADD(M, DATEDIFF(M, 0, md.WinlostDate), 0) AS MonthDate
					
				FROM dbo.MemberDaily md WITH(NOLOCK)
					INNER JOIN #AffPaging m
					ON md.AffID = m.AffId
				WHERE md.SportType = ISNULL(@SportId, SportType)
					AND (@IsGetAll = 1 OR md.WinlostDate BETWEEN @FromDate AND CASE WHEN @ToDate >= @CurrDate THEN @PrevCurrDate ELSE @ToDate END)
					AND (md.Turnover > 0 OR md.Deposit > 0)
					
				GROUP BY  md.AffId
					, md.IBCCustID
					, DATEADD(M, DATEDIFF(M, 0, md.WinlostDate), 0)
					
				UNION ALL
				SELECT md.AffId
					, md.IBCCustID
					, DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0) AS MonthDate
				FROM #MemberBettrans md
				WHERE md.SportType = ISNULL(@SportId, SportType)
					AND (md.MemTurnover > 0 OR md.MemDeposit > 0)
				GROUP BY  md.AffId
					, md.IBCCustID
					--, DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0) 
			) AS t1
			GROUP BY t1.AffId
				,t1.MonthDate
		) t
		GROUP BY t.AffID
	)
	,QualifiedMember (AffId, TotalQM)
	AS (
		SELECT t.AffId
			, SUM(TotalQM)
		FROM (
			SELECT ac.AffId
				, ac.WinlostDate AS MonthDate
				, SUM(QualifiedMember) AS TotalQM
			FROM dbo.AffCommission ac WITH(NOLOCK)
				INNER JOIN #AffPaging m
				ON ac.AffID = m.AffId
			WHERE ac.SportID = ISNULL(@SportId, ac.SportID)
				AND (@IsGetAll = 1 
						OR (
							@FromDate <  @MaxCalculatedDate 
								AND ac.WinlostDate BETWEEN @FromDate AND CASE WHEN @MaxCalculatedDate > @ToDate THEN @ToDate ELSE @MaxCalculatedDate END
							)
					)
			GROUP BY ac.AffId
				, ac.WinlostDate
			HAVING SUM(QualifiedMember) > 0

			UNION ALL -- current and previous month
			SELECT r.AffId
				, MonthDate
				, COUNT(1)	AS TotalQM
			FROM (
				SELECT md.AffId
					, md.IBCCustID
					, md.SportType
					, DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0) AS MonthDate
				FROM (
					SELECT 	mt.IBCCustID
						,mt.AffID
						,mt.SportType
						,SUM(mt.Turnover * mt.AffExRate) AS Turnover
						,SUM(mt.Deposit * mt.AffExRate) AS Deposit
					FROM dbo.MemberDaily mt WITH(NOLOCK)
						INNER JOIN #AffPaging m
						ON mt.AffID = m.AffId
						
					WHERE mt.SportType = ISNULL(@SportId, SportType)
						AND (
							(@FromDate > @MaxCalculatedDate OR @ToDate > @MaxCalculatedDate)
							AND mt.WinlostDate BETWEEN (CASE WHEN @MaxCalculatedDate < @FromDate THEN @FromDate ELSE @MaxCalculatedDate END) 
												AND (CASE WHEN @ToDate >= @CurrDate THEN @PrevCurrDate ELSE @ToDate END)
						)
					GROUP BY mt.IBCCustID
						,mt.AffID
						,mt.SportType
					
					UNION 
					SELECT 	mt2.IBCCustID
						,mt2.AffID
						,mt2.SportType
						,SUM(mt2.MemTurnover) AS Turnover
						,SUM(mt2.MemDeposit) AS Deposit
					FROM #MemberBettrans mt2
					GROUP BY mt2.IBCCustID
						,mt2.AffID
						,mt2.SportType
					
				) AS md
					INNER JOIN dbo.SportType s
					ON md.SportType = s.SportId
				
				GROUP BY md.AffId
					,md.IBCCustID
					,md.SportType
					,s.QMTurnOver
					--,DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0)
					
				HAVING SUM(ISNULL(md.TurnOver, 0)) >= s.QMTurnOver
					
			) r
			GROUP BY r.AffId
				, r.MonthDate
		) t
		GROUP BY t.AffId
	)
	, RptWinLost 
	AS (
		SELECT rpt.AffId
			, SUM(ISNULL(rpt.Deposit, 0))		AS Deposit
			, SUM(ISNULL(rpt.Withdrawal, 0))	AS Withdrawal
			, SUM(ISNULL(rpt.Turnover, 0))		AS Turnover
			, SUM(ISNULL(rpt.Winlost, 0))		AS Winlost
			, SUM(ISNULL(rpt.Bonus, 0))			AS Bonus
			, SUM(ISNULL(rpt.PSP, 0))			AS PSP
			, SUM(ISNULL(rpt.Adjustment, 0))	AS Adjustment
			, SUM(ISNULL(rpt.AffAdjustment, 0)) AS AffAdjustment
			, SUM(ISNULL(rpt.AffWithdrawal, 0)) AS AffWithdrawal
			, SUM(ISNULL(rpt.AffBF, 0))			AS AffBF
			
		FROM #AffReport rpt
		GROUP BY rpt.AffId
	)
	-- sum total
	SELECT p.RowIDX
		, p.AffId
		, m.UserName

		, ISNULL(rpt.Deposit, 0)		AS Deposit
		, ISNULL(rpt.Withdrawal, 0)		AS Withdrawal
		, ISNULL(rpt.Turnover, 0)		AS Turnover
		, ISNULL(rpt.Winlost, 0)		AS Winlost
		, ISNULL(rpt.Bonus, 0)			AS Bonus
		, ISNULL(rpt.PSP, 0)			AS PSP
		, ISNULL(rpt.Adjustment, 0)		AS Adjustment
		, ISNULL(rpt.AffAdjustment, 0)	AS AffAdjustment
		, ISNULL(rpt.AffWithdrawal, 0)	AS AffWithdrawal
		, ISNULL(rpt.AffBF, 0)			AS AffBF

		, ISNULL(ot.TotalClick, 0)		AS OldTotalClick
		, ISNULL(ot.UniqueClick, 0)		AS OldUniqueClick

		, ISNULL(nt.TotalClick, 0)		AS NewTotalClick
		, ISNULL(nt.UniqueClick, 0)		AS NewUniqueClick

		, ISNULL(ms.FDMs, 0)			AS TotalFDM
		, ISNULL(ms.Signups, 0)			AS TotalSignup

		, ISNULL(am.TotalAM, 0)			AS TotalActiveMember

		, ISNULL(qm.TotalQM, 0)			AS TotalQualifiedMember

	FROM #AffPaging p 

		INNER JOIN @AffList m
		ON p.AffId = m.AffId

		-------- SUM WinLoss ------------
		LEFT JOIN RptWinLost rpt
		ON m.AffId = rpt.AffId

		-------- SUM OldTracking ------------
		LEFT JOIN OldTracking ot
		ON m.AffId = ot.AffId

		-------- SUM NewTracking ------------
		LEFT JOIN NewTracking nt
		ON m.AffId = nt.AffId

		-------- SUM MemberStats ------------
		LEFT JOIN MemberStats ms
		ON m.AffId = ms.AffId

		-------- SUM ActiveMember ------------
		LEFT JOIN ActiveMember am
		ON m.AffId = am.AffId

		-------- SUM QualifiedMember ------------
		LEFT JOIN QualifiedMember qm
		ON m.AffId = qm.AffId

	ORDER BY p.RowIDX
		
	DROP TABLE #MemberBettrans
	DROP TABLE #AffPaging
	DROP TABLE #AffReport
	DROP TABLE #OldTracking
	DROP TABLE #NewTracking
END
GO