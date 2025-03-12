/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Rpt_MarketingPage_Statistics]
	@AffId				INT
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@LanguageCodes		VARCHAR(MAX) = ''
	,@IncludedInActive	BIT = 0
AS

/*
	Created: 20201215@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Statistics - Marketing Page Statistics

	Revisions:
		- 20201215@Percy: Initialize SP [RedmineID: #146201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), TotalClick INT, UniqueClick INT)
	CREATE CLUSTERED INDEX CIX_tmpData ON #tmpData (AffMediaLink)

	IF @ToDate > @ArchiveDate
	BEGIN
		SELECT	@FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE @ArchiveDate END
				,@TDate = @ToDate

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] BETWEEN @FDate AND @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, [Date]
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		SELECT	@FDate = @FromDate
				,@TDate = CASE WHEN @ToDate < @ArchiveDate THEN @ToDate ELSE DATEADD(DAY, -1, @ArchiveDate) END

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] BETWEEN @FDate AND @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, [Date]
	END

	IF @IncludedInActive = 0
		DELETE #tmpData WHERE AffMediaLink IN (SELECT AffMediaLink FROM dbo.AffMediaLink WITH (NOLOCK) WHERE AffId = @AffId AND IsShow = 0)

	;WITH CTE_Result AS (
		SELECT AffMediaLink, LanguageCode, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM #tmpData
		GROUP BY AffMediaLink, LanguageCode
	)
	SELECT
		ISNULL(c.ChannelName, 'Others') AS ChannelName
		,r.AffMediaLink
		,m.MarketName
		,r.TotalClick
		,r.UniqueClick
	FROM CTE_Result r
		LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON r.AffMediaLink = l.AffMediaLink AND l.AffId = @AffId
		LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON l.ChannelCode = c.ChannelCode AND c.AffId = @AffId
		INNER JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
	WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')
END
GO