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
		- 20250409@Sophia: Add ChannelCode into ClickStatistics [Redmine: #223356]
		- 20250416@Sophia: Get report by timezone [RedmineID: #222401]
		- 20250505@Sophia: Fix Signups duplicated data [RedmineID: #226056]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225821]
		- 20250729@Danny:  Use table TargetCountry [RedmineID: #227560]
		
	Param:
		@FromDate: GMT+8, Date only
		@ToDate: GMT+8, Date only
		
	Notes:
	  - ClickStatistics.Date contains Date only, in GMT-4
	  - ClickStatistics.UpdatedTime is DateTime in GMT-4
	  - MemberInfo dates are DateTime in GMT+8
	  - @ArchiveDate is in GMT-4, the maximum date in ClickStatistics_bk
*/

BEGIN
	SET NOCOUNT ON

	-- Normalize date parameters to start/end of day
	SELECT @FromDate = CONVERT(DATE, @FromDate)
	SELECT @ToDate = CONVERT(DATE, DATEADD(DAY, 1, @ToDate))

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate = dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics') -- GMT-4, Date only
	
	-- Convert from GMT+8 to GMT-4 for date comparison with ClickStatistics.Date
	DECLARE @FromDate_GMT4 DATETIME, @ToDate_GMT4 DATETIME
	SELECT @FromDate_GMT4 = DATEADD(HOUR, -12, CAST(@FromDate AS DATETIME)), -- GMT+8 to GMT-4
	       @ToDate_GMT4 = DATEADD(HOUR, -12, CAST(@ToDate AS DATETIME)) -- GMT+8 to GMT-4

	DECLARE @TmpFromDate SMALLDATETIME, @TmpToDate SMALLDATETIME

	CREATE TABLE #tmpData (AffMediaLink VARCHAR(500), LanguageCode VARCHAR(10), ChannelCode VARCHAR(50), TotalClick INT DEFAULT(0), IP VARCHAR(25), SignUps INT DEFAULT(0), FDM INT DEFAULT(0))
	CREATE CLUSTERED INDEX CIX_tmpData ON #tmpData (AffMediaLink)
	
	CREATE TABLE #tmp_Result (ChannelName NVARCHAR(200), LanguageCode VARCHAR(10), AffMediaLink VARCHAR(500), MarketName NVARCHAR(50), TotalClick INT, UniqueClick INT, SignUps INT, FDM INT, IsShow BIT)
	
	-- Signups, FDM --		
	INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, SignUps, FDM)
	SELECT
		COALESCE(c.AffMediaLink, bk.AffMediaLink, ''), 
		COALESCE(c.LanguageCode, bk.LanguageCode,''), 
		COALESCE(c.ChannelCode, bk.ChannelCode,''),
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics c WITH (NOLOCK) ON c.clickId = mi.clickId
		LEFT JOIN dbo.ClickStatistics_bk bk WITH (NOLOCK) ON bk.clickId = mi.clickId
	WHERE mi.AffId = @AffID
		AND (
				(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
				OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
			)
	GROUP BY
		COALESCE(c.AffMediaLink, bk.AffMediaLink, ''), 
		COALESCE(c.LanguageCode, bk.LanguageCode,''), 
		COALESCE(c.ChannelCode, bk.ChannelCode,'')
		
	
	IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate -- For current data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for click data
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate THEN CONVERT(DATE, @FromDate_GMT4) ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, IP)
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode, IP
			
		
	END

	IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate -- For archived data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END

		INSERT INTO #tmpData (AffMediaLink, LanguageCode, ChannelCode, TotalClick, IP)
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffId
		GROUP BY AffMediaLink, LanguageCode, ChannelCode, IP

		
	END

	;WITH CTE_Result AS (
		SELECT AffMediaLink, LanguageCode, ChannelCode, SUM(TotalClick) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick, SUM(SignUps) AS SignUps, SUM(FDM) AS FDM
		FROM #tmpData
		GROUP BY AffMediaLink, LanguageCode, ChannelCode
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
		LEFT JOIN dbo.TargetCountry m WITH (NOLOCK) ON r.LanguageCode = m.ShortedCode
		LEFT JOIN dbo.AffMediaChannel c WITH (NOLOCK) ON r.ChannelCode = c.ChannelCode AND c.AffId = @AffId	
		LEFT JOIN dbo.AffMediaLink l WITH (NOLOCK) ON r.AffMediaLink = l.AffMediaLink AND l.AffId = @AffId AND M.MarketId = l.LanguageCode	
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