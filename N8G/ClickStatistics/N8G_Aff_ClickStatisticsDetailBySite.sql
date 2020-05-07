/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
	@AffID INT
	,@Domain NVARCHAR(300) = NULL
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType TINYINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Report click statistics by Referrer site - Detail

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result TABLE
	(
		UrlReferrer		NVARCHAR(300),
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
		INSERT INTO @Result (URLReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics WITH (NOLOCK)
			WHERE [Date] >= @FromDate AND [Date] < @ToDate
				AND [Date] > @ArchiveDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType, [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		INSERT INTO @Result (URLReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE [Date] >= @FromDate AND [Date] < @ToDate
				AND [Date] <= @ArchiveDate
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0), [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END

	--count nrows
	SELECT @NRows = COUNT(1) FROM (SELECT URLReferrer FROM @Result WHERE DeviceType = @DeviceType GROUP BY URLReferrer) AS r

	IF ISNULL(@NRows, 0) = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1
		
	-- count Singups & FDM info
	CREATE TABLE #memberStats
	(
		URLReferrer NVARCHAR(600),
		DeviceType	TINYINT,
		Signups		BIGINT,
		FDM			BIGINT
	)

	;WITH memberStats AS (
		SELECT
			ISNULL(md.URLReferrer, 'none') AS URLReferrer,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.CreatedDate >= @FromDate AND mi.CreatedDate < @ToDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.CustId = mi.CustId
		WHERE mi.AffId = @AffID
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.CustId = mi.CustId
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY ISNULL(md.URLReferrer, 'none'), ISNULL(md.DeviceType, 0)
	)
	INSERT INTO #memberStats (URLReferrer, DeviceType, Signups, FDM)
	SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY URLReferrer, DeviceType

	;WITH CTE_UrlReferrer AS
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY URLReferrer) AS TheCount,
			URLReferrer
		FROM (
			SELECT DISTINCT URLReferrer
			FROM (
				SELECT TOP (@RowEnd) URLReferrer FROM @Result WHERE DeviceType = @DeviceType ORDER BY URLReferrer
				UNION ALL
				SELECT TOP (@RowEnd) URLReferrer FROM #memberStats WHERE DeviceType = @DeviceType ORDER BY URLReferrer
			) A
		) B
	)

	SELECT
		c.UrlReferrer,
		ISNULL(r.TotalClick, 0) TotalClick,
		ISNULL(r.UniqueClick, 0) UniqueClick,
		ISNULL(m.Signups, 0) Signups,
		ISNULL(m.FDM, 0) FDM
	FROM CTE_UrlReferrer c
		LEFT JOIN @Result r ON c.URLReferrer = r.URLReferrer AND r.DeviceType = @DeviceType
		LEFT JOIN #memberStats m ON c.URLReferrer = m.URLReferrer AND m.DeviceType = @DeviceType
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd

	DROP TABLE #memberStats
END
GO