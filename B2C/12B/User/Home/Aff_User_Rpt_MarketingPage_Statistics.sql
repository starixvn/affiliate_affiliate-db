/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Rpt_MarketingPage_Statistics]
	@AffId				INT
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@LanguageCodes		VARCHAR(MAX) = ''
	,@IncludedInActive	BIT = 0
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Statistics - Marketing Page Statistics

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
        - 20250221@Sally: Enhance AFFMediaLink  [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON
    DECLARE @ReportMarketingStatistics_CutOffDate SMALLDATETIME
     SELECT @ReportMarketingStatistics_CutOffDate = dbo.Aff_f_GetSetting('ReportMarketingStatistics_CutOffDate')

	SELECT  @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME, @FromDate3 SMALLDATETIME, @ToDate3 SMALLDATETIME

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))
	SELECT  @FromDate3 	 = CASE WHEN @FromDate < @ReportMarketingStatistics_CutOffDate THEN @ReportMarketingStatistics_CutOffDate ELSE @FromDate END
	SELECT	@ToDate3 	 = DATEADD(DAY, 1, @ToDate)

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT)
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

	CREATE TABLE #tmp_Result (ChannelName NVARCHAR(200), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT)
	;WITH CTE_MemberInfo AS (  
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,COUNT(1)AS SignUps   
				,0 AS FDM
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND RegisteredDate >= @FromDate3 
				AND RegisteredDate < @ToDate3 
			GROUP BY ISNULL(m.AffMediaLinkId, 0)  
			UNION ALL
			SELECT ISNULL(m.AffMediaLinkId, 0) AS AffMediaLinkId  
				,0 AS SignUps
				,COUNT(1)AS FDM  
			FROM dbo.MemberInfo m WITH (NOLOCK)  
			WHERE AffId = @AffId    
				AND FirstDepositDate >= @FromDate3 
				AND FirstDepositDate < @ToDate3 
			GROUP BY ISNULL(m.AffMediaLinkId, 0)  
	) ,
	CTE_SigupsData AS(
		SELECT AffMediaLinkId, SUM(SignUps) as SignUps, SUM(FDM)AS FDM  
		FROM CTE_MemberInfo
		GROUP BY AffMediaLinkId
	)
	INSERT INTO #tmp_Result (ChannelName, AffMediaLink, MarketName, SignUps, FDM)
		SELECT CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END AS ChannelName
			,l.AffMediaLink
			,m.MarketName
			,SUM(s.SignUps) AS SignUps
			,SUM(s.FDM) AS FDM
		FROM CTE_SigupsData  s
			LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON s.AffMediaLinkId = l.AffMediaLinkId
			LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON l.ChannelCode = c.ChannelCode AND c.AffId = @AffId
			LEFT JOIN dbo.Market m WITH (NOLOCK) ON l.LanguageCode = m.MarketId
		WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')
			AND (ISNULL(@IncludedInActive, 0) = 0 OR l.IsShow = 1)
		GROUP BY CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END 
			,l.AffMediaLink
			,m.MarketName

	;WITH CTE_Result AS (
		SELECT AffMediaLink, LanguageCode, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM #tmpData
		GROUP BY AffMediaLink, LanguageCode
	)
	INSERT INTO #tmp_Result (ChannelName, AffMediaLink, MarketName, TotalClick, UniqueClick)
	SELECT
		CASE WHEN ISNULL(c.ChannelName, '') ='' THEN 'Others' ELSE c.ChannelName END AS ChannelName
		,r.AffMediaLink
		,m.MarketName
		,r.TotalClick
		,r.UniqueClick
	FROM CTE_Result r
		LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON r.AffMediaLink = l.AffMediaLink AND l.AffId = @AffId
		LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON l.ChannelCode = c.ChannelCode AND c.AffId = @AffId
		INNER JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
	WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')

	SELECT ChannelName, AffMediaLink, MarketName
		,SUM(ISNULL(TotalClick,0)) AS TotalClick 
		,SUM(ISNULL(UniqueClick,0)) AS UniqueClick
		,SUM(ISNULL(SignUps,0)) AS SignUps
		,SUM(ISNULL(FDM,0)) AS FDM
	FROM #tmp_Result
	GROUP BY ChannelName, AffMediaLink, MarketName

	DROP TABLE #tmpData
	DROP TABLE #tmp_Result
END
GO