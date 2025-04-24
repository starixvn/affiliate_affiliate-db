/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelBySite] 
	@AffID INT
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType SMALLINT = -1
	,@TotalClicks INT = 0 OUTPUT
	,@UniqueClicks INT = 0 OUTPUT
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Report click statistics by Referrer site

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201109@Percy: Change way to get FDM [RedmineID: #145020]
		- 20220629@Malcolm: Support an Affiliate remove player [RedmineID: #173640]
		- 20250324@Sophia: Count Signups, FDM by clickId [RedmineID: 221818]
		- 20250416@Sophia: Get report by timezone [RedmineID: 222401]
		
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
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		TotalClick		INT DEFAULT(0),
		UniqueClick		INT DEFAULT(0),
		Signups			INT DEFAULT(0),
		FDM				INT DEFAULT(0)
	)

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
	
	IF CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate -- For current data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for click data
		SELECT @TmpFromDate = CASE WHEN CONVERT(DATE, @FromDate_GMT4) > @ArchiveDate THEN CONVERT(DATE, @FromDate_GMT4) ELSE DATEADD(Day, 1, @ArchiveDate) END,
		       @TmpToDate = DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4))
				
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0), SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
		GROUP BY ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0)
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, Signups, FDM)
		SELECT
			ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
			ISNULL(md.DeviceType, 0)			AS DeviceType,
			COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
					OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
				)
		GROUP BY
			ISNULL(md.DomainReferrer, 'none'),
			ISNULL(md.DeviceType, 0)
			
			IF CONVERT(DATE, @FromDate_GMT4) = @ArchiveDate -- Should retrieve data at ClickStatistics_bk for boundary date
			BEGIN
				INSERT INTO #tmpResult (DomainReferrer, DeviceType, Signups, FDM)
				SELECT
					ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
					ISNULL(md.DeviceType, 0)			AS DeviceType,
					COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
					COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					LEFT JOIN dbo.ClickStatistics_bk md WITH (NOLOCK) ON md.clickId = mi.clickId
				WHERE mi.AffId = @AffID
					AND (
							(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
							OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
						)
					AND md.Date = @ArchiveDate
				GROUP BY
					ISNULL(md.DomainReferrer, 'none'),
					ISNULL(md.DeviceType, 0)
			END
	END
	
	IF CONVERT(DATE, @FromDate_GMT4) <= @ArchiveDate -- For archived data
	BEGIN
		-- Calculate date ranges in GMT-4 timezone for archived click data
		SELECT @TmpFromDate = CONVERT(DATE, @FromDate_GMT4), 
		       @TmpToDate = CASE WHEN CONVERT(DATE, @ToDate_GMT4) > @ArchiveDate THEN DATEADD(Day, 1, @ArchiveDate) ELSE DATEADD(Day, 1, CONVERT(DATE, @ToDate_GMT4)) END
	
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0), SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @TmpFromDate AND [Date] < @TmpToDate
			AND UpdatedTime >= @FromDate_GMT4 AND UpdatedTime < @ToDate_GMT4 -- Use GMT-4 dates for UpdatedTime
			AND AffId = @AffID
		GROUP BY ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0)
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, Signups, FDM)
		SELECT
			ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
			ISNULL(md.DeviceType, 0)			AS DeviceType,
			COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics_bk md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate)	 
					OR (mi.FirstDepositDate >= @FromDate AND mi.FirstDepositDate < @ToDate)
				)
			AND md.[Date] >= @TmpFromDate AND md.[Date] < @TmpToDate -- Filter by date range
		GROUP BY
			ISNULL(md.DomainReferrer, 'none'),
			ISNULL(md.DeviceType, 0)
	END
 
	-- Return data --
	CREATE TABLE #SumResult (
		DomainReferrer NVARCHAR(600),
		TotalClick INT,
		UniqueClick INT,
		Signups INT,
		FDM INT
	)
	
	INSERT INTO #SumResult (DomainReferrer, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		DomainReferrer,
		SUM(TotalClick) AS TotalClick,
		SUM(UniqueClick) AS UniqueClick,
		SUM(Signups) AS Signups,
		SUM(FDM) AS FDM
	FROM #tmpResult
	WHERE (DeviceType = @DeviceType OR @DeviceType = -1)
	GROUP BY DomainReferrer

	SELECT @TotalClicks = SUM(TotalClick), @UniqueClicks = SUM(UniqueClick),
           @TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM #SumResult

	SELECT
		DomainReferrer,
		TotalClick,
		UniqueClick,
		Signups,
		FDM
	FROM #SumResult
	ORDER BY DomainReferrer

	DROP TABLE #tmpResult
	DROP TABLE #SumResult
END
GO