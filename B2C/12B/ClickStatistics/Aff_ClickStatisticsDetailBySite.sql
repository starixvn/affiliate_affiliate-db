/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
	@AffID INT
	,@Domain NVARCHAR(300) = NULL
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType SMALLINT = -1
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Report click statistics by Referrer site - Detail

	Revisions:  
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250324@Sophia: Count Signups, FDM by clickId [RedmineID: 219949]
		- 20250402@Sophia: Get ClickStatistics_bk, remove GroupBy Date for UniqueClick [RedmineID: #222777]
		- 20250416@Sophia: Get report by timezone [RedmineID: #222352]
		- 20250505@Sophia: Fix Signups duplicated data [RedmineID: #226056]
		- 20250506@Sophia: Fix IP handling in UniqueClick [RedmineID: #225820]
		- 20250515@Lewis: @LanguageCode => MarketId [RedmineID: #227338]
		- 20250522@Lewis: ClickId NULL [RedmineID: #228311]
	
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

	CREATE TABLE #Result (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT, IP NVARCHAR(25), Signups INT, FDM INT)
	CREATE TABLE #SumResult (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT, UniqueClick INT, Signups INT, FDM INT)
	
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
	
	;WITH memberStats AS (
	SELECT
		COALESCE(md.URLReferrer, bk.URLReferrer, 'none') AS URLReferrer,
		COALESCE(md.DeviceType, bk.DeviceType, 0) AS DeviceType,
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickID = mi.clickID
		LEFT JOIN dbo.ClickStatistics_bk bk WITH (NOLOCK) ON bk.clickID = mi.clickID
		LEFT JOIN @ShortedCode sc ON sc.ShortedCode = ISNULL(md.LanguageCode, bk.LanguageCode)
	WHERE mi.AffId = @AffID
		AND (@Domain IS NULL OR COALESCE(md.DomainReferrer,bk.DomainReferrer, 'none') = @Domain)
		AND (@SportCode IS NULL OR COALESCE(md.SportCode,bk.SportCode, 'none') = @SportCode)	
		AND (	
				(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
				OR	(mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
			)						
	GROUP BY COALESCE(md.URLReferrer, bk.URLReferrer, 'none'), COALESCE(md.DeviceType, bk.DeviceType, 0) 
	)
	INSERT INTO #Result (URLReferrer, DeviceType, Signups, FDM)
	SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY URLReferrer, DeviceType
	
	
	IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate -- For current data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for click data
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate THEN CONVERT(DATE, @FromDate_GMT4) ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))
				
		INSERT INTO #Result (URLReferrer, DeviceType, TotalClick, IP)
		SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND EXISTS (SELECT TOP 1 1 FROM @ShortedCode sc WHERE sc.ShortedCode = c.LanguageCode)
		GROUP BY URLReferrer, DeviceType, IP
		
				
	END

	IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate -- For archived data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END

		INSERT INTO #Result (URLReferrer, DeviceType, TotalClick, IP)
		SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, SUM(1) AS TotalClick, IP
		FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate  -- Use date-only comparison
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID 
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND EXISTS (SELECT TOP 1 1 FROM @ShortedCode sc WHERE sc.ShortedCode = c.LanguageCode)
		GROUP BY URLReferrer, ISNULL(DeviceType, 0), IP
		
		
	END

	INSERT INTO #SumResult (URLReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(URLReferrer, 'none'),
		ISNULL(DeviceType, 0),
		SUM(TotalClick) AS TotalClick,
		COUNT(DISTINCT IP) AS UniqueClick, -- Count distinct IP for UniqueClick
		SUM(Signups) AS Signups,
		SUM(FDM) AS FDM
	FROM #Result
	GROUP BY ISNULL(URLReferrer, 'none'), ISNULL(DeviceType, 0)

	--count nrows
	SELECT @NRows = COUNT(1) FROM (SELECT URLReferrer FROM #SumResult WHERE (DeviceType = @DeviceType OR @DeviceType = -1) GROUP BY URLReferrer) AS r

	IF ISNULL(@NRows, 0) = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1		
		
	;WITH CTE_UrlReferrer AS
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY URLReferrer) AS TheCount,
			URLReferrer, DeviceType
		FROM (
			SELECT DISTINCT URLReferrer, DeviceType
			FROM (
				SELECT TOP (@RowEnd) URLReferrer, DeviceType FROM #SumResult WHERE (DeviceType = @DeviceType OR @DeviceType = -1) ORDER BY URLReferrer
			) A
		) B
	)

	SELECT
		c.UrlReferrer,
		ISNULL(r.TotalClick, 0) TotalClick,
		ISNULL(r.UniqueClick, 0) AS UniqueClick,
		ISNULL(r.Signups, 0) Signups,
		ISNULL(r.FDM, 0) FDM
	FROM CTE_UrlReferrer c
		LEFT JOIN #SumResult r ON c.URLReferrer = r.URLReferrer AND r.DeviceType = c.DeviceType 
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd
		AND (c.DeviceType = @DeviceType OR @DeviceType = -1)

	DROP TABLE #Result
	DROP TABLE #SumResult
END
GO