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
		- 20250326@Sophia: Use data of ClickStatistics.AffMediaLink via ClickId [RedmineID: #220954]
 
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate)
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate =  dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics')

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT)
	CREATE CLUSTERED INDEX CIX_tmpData ON #tmpData (AffMediaLink)
	
	CREATE TABLE #tmp_Result (ChannelName NVARCHAR(200),LanguageCode VARCHAR(10), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT, IsShow BIT)
	

	IF @ToDate > @ArchiveDate
	BEGIN
		SELECT  @FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE DATEADD(Day,1,@ArchiveDate) END 
				,@TDate = DATEADD(Day,1,@ToDate)

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode 
		
		-- Signups, FDM --		
		INSERT INTO #tmpData (AffMediaLink, LanguageCode, SignUps, FDM)
		SELECT
			c.AffMediaLink, c.LanguageCode,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics c WITH (NOLOCK) ON c.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
		GROUP BY
			c.AffMediaLink, c.LanguageCode
		-- End Signups, FDM -- 
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		SELECT  @FDate = @FromDate 
				,@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, TotalClick, UniqueClick)
		SELECT AffMediaLink, LanguageCode, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode 

		-- Signups, FDM --
		INSERT INTO #tmpData (AffMediaLink, LanguageCode, SignUps, FDM)
		SELECT
			c.AffMediaLink, c.LanguageCode,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics_bk c WITH (NOLOCK) ON c.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
		GROUP BY
			c.AffMediaLink, c.LanguageCode
		-- End Signups, FDM --		
	END


	;WITH CTE_Result AS (
		SELECT AffMediaLink, LanguageCode, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick, SUM (SignUps) as SignUps, SUM (FDM) as FDM
		FROM #tmpData
		GROUP BY AffMediaLink, LanguageCode
	)
	INSERT INTO #tmp_Result (ChannelName, AffMediaLink, MarketName, TotalClick, UniqueClick, SignUps, FDM, IsShow)
	SELECT
		ISNULL(c.ChannelName, 'Others') AS ChannelName
		,r.AffMediaLink
		,m.MarketName
		,r.TotalClick
		,r.UniqueClick
		,r.SignUps
		,r.FDM
		,ISNULL(l.IsShow,1)	
	FROM CTE_Result r
		LEFT JOIN dbo.Market m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
		LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON r.AffMediaLink = l.AffMediaLink AND l.AffId = @AffId AND M.MarketId = l.LanguageCode
		LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON l.ChannelCode = c.ChannelCode AND c.AffId = @AffId	
	WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')

	
	IF @IncludedInActive = 0
		DELETE #tmp_Result WHERE IsShow = 0


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