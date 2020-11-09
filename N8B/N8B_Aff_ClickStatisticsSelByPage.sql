/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage] 
	@AffID INT
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@DeviceType TINYINT = 0
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Report click statistics by Landing page and language of landing page

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT,
		Signups			INT,
		FDM				INT,
		Sort			TINYINT DEFAULT (0)
	)
	
	DECLARE @Result TABLE
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT
	)
	
	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120),
			@ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120)
			
	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))

	IF @ToDate > @ArchiveDate
	BEGIN
		INSERT INTO @Result (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
		SELECT SportCode, LanguageCode, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND [Date] > @ArchiveDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY SportCode, LanguageCode, DeviceType, [Date]
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		INSERT INTO @Result (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
		SELECT SportCode, LanguageCode, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM dbo.ClickStatisticsSum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND [Date] <= @ArchiveDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY SportCode, LanguageCode, DeviceType
	END

	INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM, Sort)
	SELECT ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0), SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 0
	FROM @Result
	GROUP BY ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0)

	-- End TotalClick, UniqueClick --

	-- Signups, FDM --
	INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(md.SportCode, 'none')	AS SportCode,
		ISNULL(md.LanguageCode, 'none')	AS LanguageCode,
		ISNULL(md.DeviceType, 0)		AS DeviceType,
		0								AS TotalClick,
		0								AS UniqueClick,
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.CustId = mi.CustId
	WHERE mi.AffId = @AffID
		AND (@SportCode IS NULL OR ISNULL(SportCode, 'none') = @SportCode)
		AND (@LanguageCode IS NULL OR ISNULL(LanguageCode, 'none') = @LanguageCode)
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.CustId = mi.CustId
				AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
		)
	GROUP BY
		ISNULL(md.SportCode, 'none'),
		ISNULL(md.LanguageCode, 'none'),
		ISNULL(md.DeviceType, 0)

	-- Return data --
	SELECT
		SportCode,
		LanguageCode,
		SUM(TotalClick)		AS TotalClick,
		SUM(UniqueClick)	AS UniqueClick,
		SUM(Signups)		AS Signups,
		SUM(FDM)			AS FDM
	FROM #tmpResult
	WHERE DeviceType = @DeviceType
	GROUP BY SportCode, LanguageCode, Sort
	ORDER BY Sort

	SELECT	@TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM	#tmpResult
	WHERE	DeviceType = @DeviceType

	DROP TABLE #tmpResult
END
GO