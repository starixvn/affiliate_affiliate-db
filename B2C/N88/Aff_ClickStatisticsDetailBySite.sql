/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
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
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Report click statistics by Referrer site - Detail

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20221214@Malcolm: Get statistics by affid [RedmineID: #181651]
		- 20221215@Malcolm: Group by URLReferrer [RedmineID: #181651]
		- 20250324@Sophia: Count Signups, FDM by clickId [RedmineID: 221818]
		- 20250416@Sophia: Get report by timezone [RedmineID: 222401]
		- 20250505@Sophia: Fix Signups duplicated data [RedmineID: #226056]
		
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

	CREATE TABLE #Result (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT DEFAULT(0), UniqueClick INT DEFAULT(0), Signups BIGINT DEFAULT(0), FDM BIGINT DEFAULT(0))
	CREATE TABLE #SumResult (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT DEFAULT(0), UniqueClick INT DEFAULT(0), Signups BIGINT DEFAULT(0), FDM BIGINT DEFAULT(0))

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
	WHERE mi.AffId = @AffID
		AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
		AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
		AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)			
		AND (	
				(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
				OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
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
				
		INSERT INTO #Result (URLReferrer, DeviceType, TotalClick, UniqueClick)		
		SELECT ISNULL(URLReferrer, 'none'), ISNULL(DeviceType, 0), SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY ISNULL(URLReferrer, 'none'), ISNULL(DeviceType, 0)
		
		
	END

	IF CONVERT(DATE, @FromDate_GMT4) < @ArchiveDate -- For archived data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END
	
		INSERT INTO #Result (URLReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT ISNULL(URLReferrer, 'none'), ISNULL(DeviceType, 0), SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID 
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY ISNULL(URLReferrer, 'none'), ISNULL(DeviceType, 0) 

	END

	INSERT INTO #SumResult (URLReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick, 
	       SUM(Signups) AS Signups, SUM(FDM) AS FDM
	FROM #Result
	GROUP BY URLReferrer, DeviceType

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
		ISNULL(r.UniqueClick, 0) UniqueClick,
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