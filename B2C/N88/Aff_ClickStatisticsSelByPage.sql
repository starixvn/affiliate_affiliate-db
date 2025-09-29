/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage] 
	@AffID INT
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@DeviceType SMALLINT = -1
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Report click statistics by Landing page and language of landing page

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20250324@Sophia: Count Signups, FDM by clickId [RedmineID: 221818]
		- 20250416@Sophia: Get report by timezone [RedmineID: 222401]
		- 20250505@Sophia: Fix Signups duplicated data [RedmineID: #226056]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225821]
		- 20250926@Lewis: use marketid for param @LanguageCode and data ouptut column LanguageCode [RedmineID: #238489]
		
	Param:
		@DeviceType = -1 : all 
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

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		TotalClick		INT DEFAULT(0),
		IP				VARCHAR(25),  
		Signups			INT DEFAULT(0),
		FDM				INT DEFAULT(0)
	)
	
	-- get ShortedCode
	DECLARE @ShortedCode TABLE (ShortedCode VARCHAR(10))

	INSERT INTO @ShortedCode (ShortedCode)
	SELECT DISTINCT ShortedCode 
	FROM TargetCountry WITH (NOLOCK) 
	WHERE MarketID = @LanguageCode OR @LanguageCode IS NULL

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
	
	-- Signups, FDM --
	INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, Signups, FDM)
	SELECT
		COALESCE(md.SportCode, bk.SportCode, 'none') AS SportCode,
		COALESCE(md.LanguageCode, bk.LanguageCode, 'none')	AS LanguageCode,
		COALESCE(md.DeviceType, bk.DeviceType, 0) AS DeviceType,
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickId = mi.clickId
		LEFT JOIN dbo.ClickStatistics_bk bk WITH (NOLOCK) ON bk.clickId = mi.clickId
		LEFT JOIN @ShortedCode sc ON sc.ShortedCode = ISNULL(md.LanguageCode, bk.LanguageCode)
	WHERE mi.AffId = @AffID
		AND (
				(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
				OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
			)					
		AND (@SportCode IS NULL OR COALESCE(md.SportCode, bk.SportCode, 'none') = @SportCode)
	GROUP BY
		COALESCE(md.SportCode, bk.SportCode, 'none'),
		COALESCE(md.LanguageCode, bk.LanguageCode, 'none'),
		COALESCE(md.DeviceType, bk.DeviceType, 0)	
			
			
	IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate -- For current data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for click data
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate THEN CONVERT(DATE, @FromDate_GMT4) ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))
				
		INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, IP)
		SELECT ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0), 
               SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND EXISTS (SELECT TOP 1 1 FROM @ShortedCode sc WHERE sc.ShortedCode = c.LanguageCode)
		GROUP BY ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0), IP
		
				
	END
	
	IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate -- For archived data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END
	
		INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, IP)
		SELECT SportCode, LanguageCode, DeviceType, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND EXISTS (SELECT TOP 1 1 FROM @ShortedCode sc WHERE sc.ShortedCode = c.LanguageCode)
		GROUP BY SportCode, LanguageCode, DeviceType, IP
		
		
	END

	-- Return data --
	CREATE TABLE #SumResult (
		SportCode VARCHAR(50),
		LanguageCode VARCHAR(10),
		TotalClick INT,
		UniqueClick INT,
		Signups INT,
		FDM INT
	)
	
	INSERT INTO #SumResult (SportCode, LanguageCode, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(r.SportCode, 'none') AS SportCode,
		ISNULL(tc.MarketID, 'none') AS LanguageCode,
		SUM(r.TotalClick) AS TotalClick,
		COUNT(DISTINCT r.IP) AS UniqueClick, -- Count distinct IP for UniqueClick
		SUM(r.Signups) AS Signups,
		SUM(r.FDM) AS FDM
	FROM #tmpResult r
	LEFT JOIN TargetCountry tc WITH (NOLOCK)
		ON r.LanguageCode = tc.ShortedCode
	WHERE (DeviceType = @DeviceType OR @DeviceType = -1)
	GROUP BY r.SportCode, ISNULL(tc.MarketID, 'none')

	SELECT @TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM #SumResult

	SELECT
		SportCode,
		LanguageCode,
		TotalClick,
		UniqueClick,
		Signups,
		FDM
	FROM #SumResult
	ORDER BY SportCode, LanguageCode

	DROP TABLE #tmpResult
	DROP TABLE #SumResult
END
GO