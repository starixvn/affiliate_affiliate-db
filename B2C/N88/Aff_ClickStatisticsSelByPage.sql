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
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT,
		Signups			INT,
		FDM				INT,
		Sort			TINYINT DEFAULT (0)
	)
	
	DECLARE @Result TABLE
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT
	)
	
	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120),
			@ToDate = CONVERT(VARCHAR(10), @ToDate, 120)
			
	DECLARE @ArchiveDate SMALLDATETIME
	SELECT @ArchiveDate =  dbo.Aff_f_GetSetting('ArchiveDate_ClickStatistics')
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME 

	IF @ToDate > @ArchiveDate
	BEGIN
	
		SELECT  @FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE DATEADD(Day, 1, @ArchiveDate) END, 
				@TDate = DATEADD(Day, 1, @ToDate)
		
		INSERT INTO @Result (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
		SELECT SportCode, LanguageCode, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY SportCode, LanguageCode, DeviceType 
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
		SELECT
			ISNULL(md.SportCode, 'none')	AS SportCode,
			ISNULL(md.LanguageCode, 'none')	AS LanguageCode,
			ISNULL(md.DeviceType, 0)		AS DeviceType,
			0								AS TotalClick,
			0								AS UniqueClick,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
						(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
					
			AND (@SportCode IS NULL OR ISNULL(SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(LanguageCode, 'none') = @LanguageCode)
		GROUP BY
			ISNULL(md.SportCode, 'none'),
			ISNULL(md.LanguageCode, 'none'),
			ISNULL(md.DeviceType, 0)
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		SELECT  @FDate = @FromDate, 
				@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END
		
		INSERT INTO @Result (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
		SELECT SportCode, LanguageCode, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics_bk WITH (NOLOCK)
		WHERE [Date] >= @FDate AND [Date] < @TDate	
			AND [Date] <= @ArchiveDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY SportCode, LanguageCode, DeviceType
		
		-- Signups, FDM --
		INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
		SELECT
			ISNULL(md.SportCode, 'none')	AS SportCode,
			ISNULL(md.LanguageCode, 'none')	AS LanguageCode,
			ISNULL(md.DeviceType, 0)		AS DeviceType,
			0								AS TotalClick,
			0								AS UniqueClick,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics_bk md WITH (NOLOCK) ON md.clickId = mi.clickId
		WHERE mi.AffId = @AffID
			AND (
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
						OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
				)
			AND (@SportCode IS NULL OR ISNULL(SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(LanguageCode, 'none') = @LanguageCode)
		GROUP BY
			ISNULL(md.SportCode, 'none'),
			ISNULL(md.LanguageCode, 'none'),
			ISNULL(md.DeviceType, 0)		
		
	END

	INSERT INTO #tmpResult (SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM, Sort)
	SELECT ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0), SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 0
	FROM @Result
	GROUP BY ISNULL(SportCode, 'none'), ISNULL(LanguageCode, 'none'), ISNULL(DeviceType, 0)

	-- End TotalClick, UniqueClick --
 
	-- Return data --
	SELECT
		SportCode,
		LanguageCode,
		SUM(TotalClick)		AS TotalClick,
		SUM(UniqueClick)	AS UniqueClick,
		SUM(Signups)		AS Signups,
		SUM(FDM)			AS FDM
	FROM #tmpResult
	WHERE (DeviceType = @DeviceType OR @DeviceType = -1)
	GROUP BY SportCode, LanguageCode, Sort
	ORDER BY Sort

	SELECT	@TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM	#tmpResult
	WHERE	(DeviceType = @DeviceType OR @DeviceType = -1)

	DROP TABLE #tmpResult
END
GO