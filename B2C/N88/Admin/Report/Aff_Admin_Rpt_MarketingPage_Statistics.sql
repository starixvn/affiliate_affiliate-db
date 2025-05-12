/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8G-Affiliate_N8G,DBAFFN8B-Affiliate_N8B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Rpt_MarketingPage_Statistics]
	@AffUsername VARCHAR(30) = ''
	,@FromDate SMALLDATETIME = ''
	,@ToDate SMALLDATETIME = ''
	,@LanguageCodes	VARCHAR(MAX) = ''
	,@IncludedInActive BIT = 0
	,@PageSize INT = 0
	,@PageIndex INT = 0
	,@NRows INT = 0 OUTPUT

AS
/*
	Created: 20241118@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8G-Affiliate_N8G,DBAFFN8B-Affiliate_N8B
	Task: Admin site - Home - Statistics - Marketing Page Statistics

	Revisions:
		- 20241118@Lewis: Initialize SP [RedmineID: #219779]
		- 20241118@Lewis: LanguageCode = ALL => show NULL [RedmineID: #219779]
		- 20250409@Sophia: Add ChannelCode into ClickStatistics [Redmine: #223356]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225821]
*/

BEGIN
	SET NOCOUNT ON
	/*
	--Validate @LanguageCodes
	DECLARE @tmpLanguageCodes TABLE (MarketId NVARCHAR(20), ShortedCode NVARCHAR(20), MarketName NVARCHAR(100))
	INSERT INTO @tmpLanguageCodes (MarketId,ShortedCode,MarketName)
	SELECT m.MarketId,m.ShortedCode,m.MarketName
	FROM string_split(@LanguageCodes,',') f
	INNER JOIN Market m WITH (NOLOCK) ON f.value = m.MarketId
	*/
	DECLARE @FDate_Local DATETIME
			,@TDate_Local DATETIME

	SELECT @FDate_Local = DATEADD(HOUR,-12,CAST(@FromDate AS DATETIME)) --GMT-4
			,@TDate_Local = DATEADD(HOUR,-12,DATEADD(DAY,1,CAST(@ToDate AS DATETIME))) --GMT-4

	DECLARE @FDate SMALLDATETIME
			,@TDate SMALLDATETIME

	DECLARE @RowStart INT
			,@RowEnd INT

	DECLARE @ArchiveDate SMALLDATETIME	
	SELECT	@ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics')  -- GMT-4

	DECLARE @AffId INT = 0 --getall
	IF ISNULL(@AffUsername,'') <> ''
	BEGIN
		SET @AffId = ISNULL((SELECT AffId FROM AffInfo (NOLOCK) WHERE UserName = @AffUsername),-1)
	END

	CREATE TABLE #tmp_Result (AffId INT, ChannelName NVARCHAR(200), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT)

	CREATE TABLE #tmpData (AffId INT, AffMediaLink VARCHAR(500), ShortedCode NVARCHAR(20), ChannelCode VARCHAR(50), TotalClick INT, IP VARCHAR(25), SignUps INT, FDM INT)

	SELECT	@FDate = @FromDate
			,@TDate = DATEADD(DAY,1,@ToDate) 

	--SignUp
	INSERT INTO #tmpData (AffId, AffMediaLink, ShortedCode, c.ChannelCode, SignUps)
	SELECT m.AffId, 
			COALESCE(c.AffMediaLink, b.AffMediaLink, '') as AffMediaLink, 
			COALESCE(c.LanguageCode, b.LanguageCode,'') as LanguageCode,
			COALESCE(c.ChannelCode, b.ChannelCode, '') as ChannelCode,
			COUNT(1) AS SignUps
	FROM MemberInfo m WITH (NOLOCK)
	LEFT JOIN ClickStatistics c WITH (NOLOCK)
		ON c.ClickId = m.ClickId
	LEFT JOIN ClickStatistics_bk b WITH (NOLOCK)
		ON b.ClickId = m.ClickId
	WHERE RegisteredDate >= @FDate --GMT+8
		AND RegisteredDate < @TDate --GMT+8
		AND (m.AffId = @AffId OR @AffId = 0)
	GROUP BY m.AffId, 
			COALESCE(c.AffMediaLink, b.AffMediaLink, ''), 
			COALESCE(c.LanguageCode, b.LanguageCode,''),
			COALESCE(c.ChannelCode, b.ChannelCode, '')

	--FDM
	INSERT INTO #tmpData (AffId, AffMediaLink, ShortedCode, ChannelCode, FDM)
	SELECT  m.AffId, 
			COALESCE(c.AffMediaLink, b.AffMediaLink, '') as AffMediaLink, 
			COALESCE(c.LanguageCode, b.LanguageCode,'') as LanguageCode,
			COALESCE(c.ChannelCode, b.ChannelCode, '') as ChannelCode,
			COUNT(1) AS FDM
	FROM MemberInfo m WITH (NOLOCK)
	LEFT JOIN ClickStatistics c WITH (NOLOCK)
		ON c.ClickId = m.ClickId
	LEFT JOIN ClickStatistics_bk b WITH (NOLOCK)
		ON b.ClickId = m.ClickId
	WHERE FirstDepositDate >= @FDate --GMT+8
		AND FirstDepositDate < @TDate --GMT+8
		AND (m.AffId = @AffId OR @AffId = 0)
	GROUP BY m.AffId,
			COALESCE(c.AffMediaLink, b.AffMediaLink, ''), 
			COALESCE(c.LanguageCode, b.LanguageCode,''),
			COALESCE(c.ChannelCode, b.ChannelCode, '')

	-- TODO: Range ClickStatistics
	IF CAST(@TDate_Local AS DATE) > @ArchiveDate --GMT-4
	BEGIN
		SELECT	@FDate = IIF(CAST(@FDate_Local AS DATE) <= @ArchiveDate, DATEADD(DAY, 1, @ArchiveDate),CAST(@FDate_Local AS DATE)) --GMT-4
				,@TDate = CAST(@TDate_Local AS DATE) --GMT-4

		--TotalClick, UniqueClick
		INSERT INTO #tmpData (AffId, AffMediaLink, ShortedCode, ChannelCode, TotalClick, IP)
		SELECT AffId, AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] BETWEEN @FDate AND @TDate --GMT-4
			AND (AffId = @AffId OR @AffId = 0)
			AND c.UpdatedTime >= @FDate_Local --GMT-4
			AND c.UpdatedTime < @TDate_Local --GMT-4
		GROUP BY AffId, AffMediaLink, LanguageCode, ChannelCode, IP
		
	

	END

	-- Range ClickStatistics_bk
	IF CAST(@FDate_Local AS DATE) <= @ArchiveDate --GMT-4
	BEGIN
		SELECT	@FDate = CAST(@FDate_Local AS DATE) --GMT-4
				,@TDate = IIF(CAST(@TDate_Local AS DATE) >= @ArchiveDate,@ArchiveDate,CAST(@TDate_Local AS DATE)) --GMT-4
			
		--TotalClick, UniqueClick
		INSERT INTO #tmpData (AffId, AffMediaLink, ShortedCode, ChannelCode, TotalClick, IP)
		SELECT AffId, AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] BETWEEN @FDate AND @TDate --GMT-4
			AND (AffId = @AffId OR @AffId = 0)
			AND UpdatedTime >= @FDate_Local --GMT-4
			AND UpdatedTime < @TDate_Local --GMT-4
		GROUP BY AffId, AffMediaLink, LanguageCode, ChannelCode, IP
		
	END

	IF @IncludedInActive = 0
	BEGIN
		DELETE t
		FROM #tmpData t
		INNER JOIN dbo.AffMediaLink a WITH (NOLOCK) 
			ON a.AffId = t.AffId
			AND a.AffMediaLink = t.AffMediaLink
		WHERE a.IsShow = 0
	END

	-- TODO: #tmp_Result
	;WITH CTE_Result AS (
		SELECT AffId, AffMediaLink, ShortedCode, ChannelCode, SUM(TotalClick) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick, SUM(SignUps) AS SignUps, SUM(FDM) AS FDM
		FROM #tmpData
		GROUP BY AffId, AffMediaLink, ShortedCode, ChannelCode
	)
	INSERT INTO #tmp_Result (AffId, ChannelName, AffMediaLink, MarketName, TotalClick, UniqueClick, SignUps, FDM)
	SELECT d.AffId, ISNULL(c.ChannelName,'Others'), d.AffMediaLink, m.MarketName, SUM(TotalClick), SUM(UniqueClick), SUM(SignUps), SUM(FDM)
	FROM CTE_Result d
	LEFT JOIN dbo.Market m WITH (NOLOCK) 
        ON d.ShortedCode = m.ShortedCode 
	LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) 
		ON d.ChannelCode = c.ChannelCode 
		AND c.AffId =  d.AffId
	WHERE (ISNULL(@LanguageCodes, '') = '' OR ',' + @LanguageCodes + ',' LIKE '%,' + m.MarketId + ',%')
	GROUP BY d.AffId, ISNULL(c.ChannelName,'Others'), d.AffMediaLink, m.MarketName

	-- TODO: Result
	;WITH CTE_Page AS(
		SELECT 
			DISTINCT r.AffId
				,DENSE_RANK() OVER (ORDER BY r.AffId) AS RId
		FROM #tmp_Result r
	)
	SELECT
		cte.RId
		, a.UserName AS AffUserName
		, ChannelName
		, AffMediaLink
		, MarketName
		,SUM(ISNULL(TotalClick,0)) AS TotalClick 
		,SUM(ISNULL(UniqueClick,0)) AS UniqueClick
		,SUM(ISNULL(SignUps,0)) AS SignUps
		,SUM(ISNULL(FDM,0)) AS FDM
	INTO #Final
	FROM #tmp_Result r
	INNER JOIN CTE_Page cte ON r.AffId = cte.AffId
	INNER JOIN AffInfo a WITH (NOLOCK)
		ON r.AffId = a.AffId
	GROUP BY cte.RId ,a.UserName, ChannelName, AffMediaLink, MarketName
	
	IF @PageIndex = 0 AND @PageSize = 0
	BEGIN
		SELECT 
			AffUserName
			,ChannelName
			,AffMediaLink
			,MarketName
			,TotalClick
			,UniqueClick
			,SignUps
			,FDM
		FROM #Final A
	END
	ELSE
	BEGIN
		SELECT	@PageIndex = @PageIndex - 1,
				@RowStart = @PageSize * @PageIndex + 1,
				@RowEnd = @RowStart + @PageSize - 1;
		
		SELECT @NRows = COUNT(DISTINCT RId)
		FROM #Final
		
		SELECT 
			AffUserName
			,ChannelName
			,AffMediaLink
			,MarketName
			,TotalClick
			,UniqueClick
			,SignUps
			,FDM
		FROM #Final A
		WHERE A.RId BETWEEN @RowStart AND @RowEnd
	END


	SELECT 
		SUM(ISNULL(TotalClick,0)) AS TotalClick 
		,SUM(ISNULL(UniqueClick,0)) AS UniqueClick
		,SUM(ISNULL(SignUps,0)) AS SignUps
		,SUM(ISNULL(FDM,0)) AS FDM
	FROM #tmp_Result r 

	DROP TABLE #tmpData
	DROP TABLE #tmp_Result
	DROP TABLE #Final
END
GO