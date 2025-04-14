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
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT,
		Signups			INT,
		FDM				INT,
		Sort			TINYINT DEFAULT (0)
	)

	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120),
			@ToDate = CONVERT(VARCHAR(10), @ToDate , 120)
			
	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate =  dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics')
	
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME
	
	-- TotalClick, UniqueClick --
	DECLARE @Result TABLE
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT
	)

	IF @ToDate > @ArchiveDate
	BEGIN
		SELECT  @FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE DATEADD(Day, 1, @ArchiveDate) END, 
				@TDate = DATEADD(Day, 1, @ToDate)				 
				 
		INSERT INTO @Result (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType 
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
		SELECT
			ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
			ISNULL(md.DeviceType, 0)			AS DeviceType,
			0									AS TotalClick,
			0									AS UniqueClick,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
						(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
		GROUP BY
			ISNULL(md.DomainReferrer, 'none'),
			ISNULL(md.DeviceType, 0)
		-- End Signups, FDM --
		
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		SELECT  @FDate = @FromDate, 
				@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END

		INSERT INTO @Result (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE  [Date] >= @FDate AND [Date] < @TDate			
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
		SELECT
			ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
			ISNULL(md.DeviceType, 0)			AS DeviceType,
			0									AS TotalClick,
			0									AS UniqueClick,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics_BK md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
		AND (
				(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
			)
		GROUP BY
			ISNULL(md.DomainReferrer, 'none'),
			ISNULL(md.DeviceType, 0)
		-- End Signups, FDM --
	END

	INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM, Sort)
	SELECT ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0), SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 0
	FROM @Result
	GROUP BY ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0)
	-- End TotalClick, UniqueClick --
 
	-- Return data --
	SELECT
		DomainReferrer,
		SUM(TotalClick)		AS TotalClick,
		SUM(UniqueClick)	AS UniqueClick,
		SUM(Signups)		AS Signups,
		SUM(FDM)			AS FDM
	FROM #tmpResult
	WHERE (DeviceType = @DeviceType OR @DeviceType = -1)
	GROUP BY DomainReferrer, Sort
	ORDER BY Sort

	SELECT	@TotalClicks = SUM(TotalClick), @UniqueClicks = SUM(UniqueClick)
	FROM	@Result
	WHERE	(DeviceType = @DeviceType OR @DeviceType = -1)

	SELECT	@TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM	#tmpResult
	WHERE	(DeviceType = @DeviceType OR @DeviceType = -1)

	DROP TABLE #tmpResult
END
GO