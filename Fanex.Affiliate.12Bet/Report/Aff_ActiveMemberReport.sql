/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_ActiveMemberReport] 
	@Fromdate 				DATETIME 		=	NULL
	,@Todate 				DATETIME 		= NULL
	,@IsGetAll 				BIT 			= 0
	,@UserName 				NVARCHAR(50) 	= NULL
	,@PreferredLanguage 	VARCHAR(11) 	= NULL
	,@AffType 				TINYINT 		= NULL
	,@PageSize 				INT 			= 50
	,@PageIndex 			INT 			= 1
	,@SortBy				TINYINT 		= 0
	,@NRows 				INT 			= 0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_12BET
Original: [Aff_ActiveMemberReport]
Revisions:
	- Remove TrackingCode table when inner join with ClickstatisticsSum table 
	- 20141114@Bobby: 
		+ Add sorting [@SortBy] value
		+ Remove @TotalPages
	- 20170214@Percy: Fix FDM/Signup Issue [RedmineID: #70507]
		
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @TotalPages num pages return,
	• @NRows num rows return
	• @SortBy: Default(0) - AffId ASC, 1 - Total Signup DESC
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CurrMonth	DATETIME
		,@CurrDate		DATETIME

	DECLARE @AffList 
	AS TABLE (
		AffId		INT
		, UserName	VARCHAR(30)
		, IsClosed	BIT
	)
	CREATE TABLE #AffTotal(
		AffId		INT
		, Signup	INT
		, FDM		INT
		, RowIDX	INT
		, NRows		INT
	)
	
	SELECT @UserName = '%' + Coalesce(@UserName, '') + '%'

	SELECT @ToDate		= DATEADD(s, -1, DATEADD(DAY, DATEDIFF(DAY, 0, @ToDate) + 1, 0))
		, @CurrDate		= GETDATE()
		, @CurrMonth	= DATEADD(M, DATEDIFF(M, 0, @CurrDate), 0)

	--count nrows
	
	INSERT INTO @AffList( AffId, UserName, IsClosed )
	SELECT ai.AffID
		, ai.UserName
		, ai.IsClosed
		
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) 
		ON ai.AffId = ad.AffId
	WHERE ai.STATUS = 'Approved'
		AND ai.Username LIKE @UserName
		AND (@PreferredLanguage IS NULL OR ad.PreferredLanguage = @PreferredLanguage) 
		AND (@AffType IS NULL OR ai.AffType = @AffType)
		AND (
			@IsGetAll = 1
			OR ai.ApprovedDate <= @Todate
		)
	
	IF (@@ROWCOUNT = 0) RETURN
	
	-- Check IsAll row
	SELECT @PageSize = CASE 
						WHEN @IsGetAll = 1 THEN @NRows 
						ELSE @PageSize 
					END
		,@PageIndex = CASE 
						WHEN @IsGetAll = 1 THEN 1 
						ELSE @PageIndex 
					END

	/*
	CREATE TABLE #custInfo (custid INT, creatdate DATETIME)
	INSERT INTO #custInfo (custid, creatdate)
	SELECT c.custid, c.creatdate
	FROM bodb02.dbo.Customer c WITH(NOLOCK)
	WHERE roleid = 1
		AND creatdate BETWEEN @FromDate AND @ToDate
	*/
	
	DECLARE @TrackingCode TABLE (AffId INT, IBCCustID INT, TrackingDate DATETIME, IsFDM BIT, IsNew BIT)
	
	INSERT INTO @TrackingCode (AffId, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT mi.AffId, mi.IBCCustID, mi.CreatedDate, 1, 1
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
		AND EXISTS (SELECT 1 FROM @AffList a WHERE mi.AffID = a.AffId)
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.IBCCustID = mi.IBCCustID
				AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
		)

	INSERT INTO @TrackingCode (AffId, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT md.AffID, md.IBCCustID, md.CreatedDate, 0, 1
	FROM dbo.MemberClickDetail md WITH (NOLOCK)
	WHERE md.CreatedDate BETWEEN @FromDate AND @ToDate
		AND EXISTS (SELECT 1 FROM @AffList a WHERE md.AffID = a.AffId)
	
	/*
	INSERT INTO @TrackingCode (AffId, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT dc.AffiliateId, dc.IBCCustID, dc.CreatDate, 0, 0
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer dc WITH (NOLOCK)
	WHERE EXISTS (SELECT 1 FROM @AffList a WHERE dc.AffiliateId = a.AffId)
		AND dc.CreatDate BETWEEN @FromDate AND @ToDate

	INSERT INTO @TrackingCode (AffId, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT dc.AffiliateId, dc.IBCCustID, c.creatdate, 1, 0
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer dc WITH (NOLOCK)
		INNER JOIN #custInfo c ON dc.IBCCustID = c.custid
	WHERE EXISTS (SELECT 1 FROM @AffList a WHERE dc.AffiliateId = a.AffId)

	DELETE t1
	FROM @TrackingCode t1
		INNER JOIN @TrackingCode t2
			ON t1.AffId = t2.AffId
				AND ISNULL(t1.IBCCustID, 0) = ISNULL(t2.IBCCustID, 0) AND t1.TrackingDate = t2.TrackingDate
				AND t1.IsNew = 0 AND t2.IsNew = 1
				AND t1.IsFDM = t2.IsFDM
	*/

	;WITH MemberStats (AffId, Signup, FDM) AS
	(
		SELECT AffId, SUM(CASE WHEN IsFDM = 1 THEN 0 ELSE 1 END) AS Signup, COUNT(CASE WHEN IsFDM = 1 THEN IBCCustID ELSE NULL END) AS FDM
		FROM @TrackingCode
		GROUP BY AffId
	)
	INSERT INTO #AffTotal(AffId, Signup, FDM, RowIDX, NRows)
	SELECT AffId, Signup, FDM, RowIDX, NRows
	FROM (
		SELECT m.AffId
			,ISNULL(ms.Signup, 0) 	AS Signup
			,ISNULL(ms.FDM, 0)		AS FDM
			,ROW_NUMBER() OVER ( 
						ORDER BY m.IsClosed ASC
								,CASE WHEN @SortBy = 1 THEN ISNULL(ms.Signup, 0) ELSE 0 END DESC
								,CASE WHEN @SortBy = 0 THEN m.AffId ELSE 0 END ASC
					) AS RowIDX
			,r.NRows
		FROM @AffList m
			INNER JOIN MemberStats ms ON m.AffId = ms.AffId
			CROSS APPLY (
				SELECT COUNT(1) AS NRows 
				FROM MemberStats
			) r
	) t
	WHERE t.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	ORDER BY t.RowIDX
	
	SELECT TOP 1 @NRows = NRows FROM #AffTotal

	-- TotalClick, UniqueClick --
	CREATE TABLE #OldTracking (AffId INT, TotalClick INT, UniqueClick INT)
	CREATE TABLE #NewTracking (AffId INT, TotalClick INT, UniqueClick INT)

	DECLARE @MaxSumDate SMALLDATETIME, @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME
	SELECT  @MaxSumDate = MAX(Date) FROM dbo.ClickStatisticsSum WITH(NOLOCK)

		/* Old */
	
	IF @FromDate < @MaxSumDate
	BEGIN
		IF DAY(@FromDate) = 1
		BEGIN
			SELECT @tmpFromDate = @FromDate
		END
		ELSE
		BEGIN
			SELECT @tmpFromDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @FromDate), 0) -- the first day of next month
		END

		IF @ToDate > @MaxSumDate
		BEGIN
			SELECT @tmpToDate = @MaxSumDate
		END
		ELSE
		BEGIN
			IF DAY(DATEADD(DAY, 1, @ToDate)) = 1
			BEGIN
				SELECT @tmpToDate = DATEADD(DAY, -1, @ToDate)
			END
			ELSE
			BEGIN
				SELECT @tmpToDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @ToDate), -1) -- the last day of previous month
			END
		END

		INSERT INTO #OldTracking
		SELECT
			c.AffID,
			SUM(c.TotalClick),
			SUM(c.UniqueClick)
		FROM dbo.ClickStatisticsSum c WITH(NOLOCK)
		WHERE Date BETWEEN @tmpFromDate AND @tmpToDate
			AND IsForMonth = 1
			AND TrackingID = 0 -- sum for months
			AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = c.AffID)
		GROUP BY c.AffID

		IF @FromDate < @tmpFromDate
		BEGIN
			INSERT INTO #OldTracking
			SELECT
				AffID,
				SUM(TotalClick),
				SUM(UniqueClick)
			FROM (
				SELECT
					t.AffID,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT s.IP) AS UniqueClick
				FROM dbo.ClickStatistics s WITH(NOLOCK)
					INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
				WHERE s.Date >= @FromDate AND s.Date < @tmpFromDate
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = t.AffID)
				GROUP BY t.AffID, s.Date
			) A
			GROUP BY AffID
		END

		IF @tmpToDate < @ToDate
		BEGIN
			INSERT INTO #OldTracking
			SELECT
				AffID,
				SUM(TotalClick),
				SUM(UniqueClick)
			FROM (
				SELECT
					t.AffID,
					COUNT(1) AS TotalClick,
					COUNT(DISTINCT s.IP) AS UniqueClick
				FROM dbo.ClickStatistics s WITH(NOLOCK)
					INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
				WHERE s.Date > @tmpToDate AND s.Date <= @ToDate
					AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = t.AffID)
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
			SUM(UniqueClick)
		FROM (
			SELECT
				t.AffID,
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
				INNER JOIN dbo.TrackingCode t WITH(NOLOCK) ON t.TrackingID = s.TrackingID
			WHERE s.Date BETWEEN @FromDate AND @ToDate
				AND EXISTS (SELECT 1 FROM #AffTotal a WHERE a.AffId = t.AffID)
			GROUP BY t.AffID, s.Date
		) A
		GROUP BY AffID
	END
		/* End Old */

		/* New */
	INSERT INTO #NewTracking
	SELECT
		c.AffID,
		COUNT(1) AS TotalClick,
		COUNT(DISTINCT c.IP) AS UniqueClick
	FROM dbo.ClickStatistics1 c WITH (NOLOCK)
	WHERE
		c.Date BETWEEN @FromDate AND @ToDate
		AND EXISTS (SELECT 1 FROM #AffTotal a WHERE c.AffId = a.AffId)
	GROUP BY c.AffID, c.Date

	INSERT INTO #NewTracking
	SELECT
		c.AffID,
		SUM(TotalClick) AS TotalClick,
		SUM(UniqueClick) AS UniqueClick
	FROM dbo.ClickStatistics1Sum c WITH (NOLOCK)
	WHERE
		(@IsGetAll = 1 OR c.Date BETWEEN @FromDate AND @ToDate)
		AND EXISTS (SELECT 1 FROM #AffTotal a WHERE c.AffId = a.AffId)
	GROUP BY c.AffID, c.Date
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
		SELECT AffId, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM #NewTracking
		GROUP BY AffId
	)
	SELECT t.AffId
		,m.UserName
		,m.IsClosed
		,t.Signup
		,t.FDM
		,ISNULL(ot.TotalClick, 0)	AS TotalClicks_Old
		,ISNULL(ot.UniqueClick, 0)	AS UniqueClicks_Old
		,ISNULL(nt.TotalClick, 0) 	AS TotalClicks_New
		,ISNULL(nt.UniqueClick, 0)	AS UniqueClicks_New
		,t.RowIDX
	FROM #AffTotal t
	
		INNER JOIN @AffList m
		ON t.AffId = m.AffId
		
		LEFT JOIN OldTracking ot
		ON t.AffId = ot.AffId
		
		LEFT JOIN NewTracking nt
		ON t.AffId = nt.AffId
		
	ORDER BY t.RowIDX
	
	DROP TABLE #AffTotal
	DROP TABLE #OldTracking
	DROP TABLE #NewTracking
	
	SET @NRows = ISNULL(@NRows, 0)
END
GO