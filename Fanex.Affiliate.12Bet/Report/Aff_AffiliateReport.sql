USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateReport] 
	@FromDate 			DATE
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
DB: DB052.Affiliate_12BET
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

Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
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
		, RowIDX		INT IDENTITY(1,1))
	
	CREATE TABLE #AffPaging(
		AffId		INT
		, RowIDX	INT
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

		SELECT @TmpToDate = DATEADD(d, - 1, @CurrDate) --To date for new way calculate winlost

		SELECT @TmpOldWayDate = @OldReportDate
	END
	ELSE
	BEGIN
		SELECT @TmpFromDate = CASE 
				WHEN @FromDate <= @OldReportDate THEN DATEADD(d, 1, @OldReportDate)
				ELSE @FromDate
				END

		SELECT @TmpToDate = CASE 
				WHEN @ToDate >= @CurrDate THEN DATEADD(d, - 1, @CurrDate)
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

	INSERT INTO @AffList(AffId, UserName)
	SELECT ai.AffId
		,ai.Username
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN AffType at WITH (NOLOCK)
		ON ai.AffType = at.TypeId
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
		
	WHERE  ai.STATUS		= 'Approved'
		AND (@AffType IS NULL OR ai.AffType	= @AffType)
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage	= @PreferredLanguage)
		
	ORDER BY ai.AffId
	
	SELECT @NRows = @@ROWCOUNT
	
	IF (ISNULL(@NRows, 0) = 0) RETURN
	
	-- Check IsAll row
	SELECT @PageSize = CASE 
						WHEN @IsGetAll = 1 THEN @NRows 
						ELSE @PageSize 
					END
		,@PageIndex = CASE 
						WHEN @IsGetAll = 1 THEN 1 
						ELSE @PageIndex 
					END
	
	INSERT INTO	#AffPaging
	SELECT m.AffId
		,m.RowIDX
	FROM @AffList m
	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY m.RowIDX
	
	IF(@ToDate >= @CurrDate)
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
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22001 THEN ISNULL(SUM((winlost - ABS(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Deposit
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype IN (22002, 22003) THEN - ISNULL(SUM((winlost - ABS(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Withdrawal
			,CASE 
				WHEN @SportId IS NULL
					AND (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399)) THEN ISNULL(SUM(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN ISNULL(ABS(stake), 0) / 2 * e.ActualRate2
								ELSE ISNULL(ABS(stake), 0) * e.ActualRate2
								END), 0)
				WHEN @SportId = @SportsBookID
					AND (BetType <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
					AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN ISNULL(SUM(ISNULL(ABS(stake), 0) * e.ActualRate2), 0)
				WHEN @SportId = @HorseRacingID
					AND bettype IN (31, 32, 33, 41, 42, 43) THEN ISNULL(SUM(CASE 
								WHEN Bettype IN (33, 43)
									AND liveawayscore = 0 THEN ISNULL(ABS(stake), 0) / 2 * e.ActualRate2
								ELSE ISNULL(ABS(stake), 0) * e.ActualRate2
								END), 0)
				ELSE 0
				END AS Turnover
			,CASE 
				WHEN @SportId IS NULL THEN ISNULL(SUM(CASE 
								WHEN (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND ruben = 1 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				WHEN @SportId = @SportsBookID THEN ISNULL(SUM(CASE 
								WHEN (bettype <= 999 OR ( b.bettype BETWEEN 1301 AND 1399))
									AND ruben = 1
									AND bettype NOT IN (31, 32, 33, 41, 42, 43) THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				WHEN @SportId = @HorseRacingID THEN ISNULL(SUM(CASE 
								WHEN bettype IN (31, 32, 33, 41, 42, 43)
									AND ruben = 1 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0)
				ELSE 0
				END AS Winlost
			,CASE 
				WHEN (
						@SportId IS NULL
						OR @SportId = @SportsBookID
						)
					AND bettype = 22004 THEN ISNULL(SUM((winlost - ABS(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Bonus
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID THEN ISNULL(SUM(CASE bettype
								WHEN 22001 THEN (winlost - ABS(actual_stake)) * e.ActualRate2
								ELSE 0
								END), 0) * e.DepositPercent + ABS(- ISNULL(SUM(CASE 
									WHEN bettype IN (22002, 22003) THEN (winlost - ABS(actual_stake)) * e.ActualRate2
									ELSE 0
									END), 0)) * e.WithdrawalPercent
				ELSE 0
				END AS PSP
			,CASE 
				WHEN @SportId IS NULL
					OR @SportId = @SportsBookID
					AND bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN ISNULL(SUM((winlost - ABS(actual_stake)) * e.ActualRate2), 0)
				ELSE 0
				END AS Adjustment
			,e.ActualRate2
		FROM bodb02.dbo.Bettrans b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK)
			ON b.CustId = m.IBCCustID	
			INNER JOIN #AffPaging ml
			ON m.AffId = ml.AffId
			INNER JOIN dbo.Exchange_Current e WITH (NOLOCK)
			ON m.Currency = e.ExchangeId
		WHERE b.WinlostDate = @CurrDate
			AND m.IsRemoved = 0
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
					--and bettype not in (31,32,33,41,42,43)   
			AND b.StatusID NOT IN (101, 102, 103, 121, 1)
			AND b.custid > 0
			
		GROUP BY m.IBCCustID
			,m.AffID
			,e.DepositPercent
			,e.WithdrawalPercent
			,b.Bettype
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
		INNER JOIN #AffPaging m
		ON ad.AffID = m.AffId
	WHERE (@IsGetAll = 1
			OR ad.WinlostDate BETWEEN @FromDate AND @TmpToDate)
		AND ISNULL(@SportId, SPortId) = SPortId
	GROUP BY ad.AffID

	--Get winlost member in Bettrans table
	IF(@ToDate >= @CurrDate)
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
		INNER JOIN #AffPaging m
		ON a.AffId = m.AffId
	WHERE (
			@IsGetAll = 1
				--OR DATEADD(d, DATEDIFF(d, 0, TransDate), 0) BETWEEN @FromDate AND DATEADD(d, DATEDIFF(d, 0, @ToDate), 0)
				OR a.TransDate BETWEEN @FromDate AND @ToDate
			)
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

		/* Old */
		-- TotalClick, UniqueClick --
	INSERT INTO #OldTracking
	SELECT
		c.AffID,
		SUM(c.TotalClick),
		SUM(c.UniqueClick),
		0 AS Signup,
		0 AS FDM
	FROM dbo.ClickStatisticsSum c WITH(NOLOCK)
	WHERE 
		(@IsGetAll = 1 OR c.Date BETWEEN @FromDate AND @ToDate)
		AND c.IsForMonth = 1
		AND c.TrackingID = 0 -- sum for months
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE a.AffId = c.AffID)
	GROUP BY c.AffID, c.Date
			
		-- Signup, FDM --
	INSERT INTO #OldTracking
	SELECT
		AffiliateID,
		0 AS TotalClick,
		0 AS UniqueClick,
		COUNT(1) AS Signup,
		COUNT(IBCCustID) AS FDM
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer c WITH (NOLOCK)
	WHERE
		(@IsGetAll = 1 OR CreatDate >= @FromDate AND CreatDate < DATEADD(DAY, 1, @ToDate))
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE c.AffiliateID = a.AffId)
	GROUP BY AffiliateID
		/* End Old */

		/* New */
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
		c.Date BETWEEN @FromDate AND @ToDate
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
		(@IsGetAll = 1 OR c.Date BETWEEN @FromDate AND @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE c.AffId = a.AffId)
	GROUP BY c.AffID, c.Date
		
		-- Signup, FDM --
	INSERT INTO #NewTracking
	SELECT
		m.AffId,
		0 AS TotalClick,
		0 AS UniqueClick,
		COUNT(1) AS Signup,
		0 AS FDM
	FROM dbo.MemberClickDetail m WITH (NOLOCK)
	WHERE
		(@IsGetAll = 1 OR CreatedDate BETWEEN @FromDate AND @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE m.AffId = a.AffId)
	GROUP BY m.AffId

	INSERT INTO #NewTracking
	SELECT
		m.AffId,
		0 AS TotalClick,
		0 AS UniqueClick,
		0 AS Signup,
		COUNT(m.IBCCustID) AS FDM
	FROM dbo.MemberInfo m WITH (NOLOCK)
	WHERE
		(@IsGetAll = 1 OR CreatedDate BETWEEN @FromDate AND @ToDate)
		AND EXISTS (SELECT 1 FROM #AffPaging a WHERE m.AffId = a.AffId)
		AND (
			@IsGetAll = 1
			OR NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.IBCCustID = m.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
				)
			)
	GROUP BY m.AffId
		/* End New */
	
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
GRANT EXECUTE ON [dbo].[Aff_AffiliateReport] TO [bodbAdminNet]
GO