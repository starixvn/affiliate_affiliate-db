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
	
	Param:
		@DeviceType = -1 : all 
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result TABLE (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT, UniqueClick INT)
	DECLARE @SumResult TABLE (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT, UniqueClick INT)

	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120)
			---@ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120)

	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))
	
	DECLARE @FDate SMALLDATETIME, @TDate SMALLDATETIME
	
	-- count Singups & FDM info
	CREATE TABLE #memberStats
	(
		URLReferrer NVARCHAR(600),
		DeviceType	TINYINT,
		Signups		BIGINT,
		FDM			BIGINT
	)
	
	IF @ToDate > @ArchiveDate
	BEGIN
	
		SELECT  @FDate = CASE WHEN @FromDate > @ArchiveDate THEN @FromDate ELSE DATEADD(Day, 1, @ArchiveDate) END, 
				@TDate = DATEADD(Day, 1, @ToDate)
				
		INSERT INTO @Result (URLReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics WITH (NOLOCK)
			WHERE [Date] >= @FDate AND [Date] < @TDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType
		) AS t
		GROUP BY URLReferrer, DeviceType
		
		
		;WITH memberStats AS (
		SELECT
			ISNULL(md.URLReferrer, 'none') AS URLReferrer,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics md WITH (NOLOCK) ON md.clickID = mi.clickID
		WHERE mi.AffId = @AffID
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)			
			AND (	
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
					)
					
		GROUP BY ISNULL(md.URLReferrer, 'none'), ISNULL(md.DeviceType, 0)
		)
		INSERT INTO #memberStats (URLReferrer, DeviceType, Signups, FDM)
		SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
		FROM memberStats
		GROUP BY URLReferrer, DeviceType
		
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		SELECT  @FDate = @FromDate, 
				@TDate = CASE WHEN @ToDate > @ArchiveDate THEN DATEADD(Day,1,@ArchiveDate) ELSE DATEADD(Day,1,@ToDate) END
	
		INSERT INTO @Result (URLReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE [Date] >= @FDate AND [Date] < @TDate	
				AND AffId = @AffID 
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0) 
		) AS t
		GROUP BY URLReferrer, DeviceType
		
		;WITH memberStats AS (
		SELECT
			ISNULL(md.URLReferrer, 'none') AS URLReferrer,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			COUNT(CASE WHEN mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate THEN 1 ELSE NULL END) AS Signups,
			COUNT(CASE WHEN mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate THEN 1 ELSE NULL END) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.ClickStatistics_bk md WITH (NOLOCK) ON md.clickID = mi.clickID
		WHERE mi.AffId = @AffID
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)
			AND (
					(mi.RegisteredDate >= @FDate AND mi.RegisteredDate < @TDate)	 
					OR	(mi.FirstDepositDate >= @FDate AND mi.FirstDepositDate < @TDate)
				)
			
		GROUP BY ISNULL(md.URLReferrer, 'none'), ISNULL(md.DeviceType, 0)
		)
		INSERT INTO #memberStats (URLReferrer, DeviceType, Signups, FDM)
		SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
		FROM memberStats
		GROUP BY URLReferrer, DeviceType
		
	END

	;WITH CTE AS
	(
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM @Result
		GROUP BY URLReferrer, DeviceType
	)
	INSERT INTO @SumResult (URLReferrer, DeviceType, TotalClick, UniqueClick)
	SELECT URLReferrer, DeviceType, TotalClick, UniqueClick
	FROM CTE

	--count nrows
	SELECT @NRows = COUNT(1) FROM (SELECT URLReferrer FROM @SumResult WHERE (DeviceType = @DeviceType OR @DeviceType = -1) GROUP BY URLReferrer) AS r

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
				SELECT TOP (@RowEnd) URLReferrer,  DeviceType FROM @SumResult WHERE (DeviceType = @DeviceType OR @DeviceType = -1) ORDER BY URLReferrer
				UNION ALL
				SELECT TOP (@RowEnd) URLReferrer, DeviceType FROM #memberStats WHERE (DeviceType = @DeviceType OR @DeviceType = -1) ORDER BY URLReferrer
			) A
		) B
	)

	SELECT
		c.UrlReferrer,
		ISNULL(r.TotalClick, 0) TotalClick,
		ISNULL(r.UniqueClick, 0) UniqueClick,
		ISNULL(m.Signups, 0) Signups,
		ISNULL(m.FDM, 0) FDM
	FROM CTE_UrlReferrer c
		LEFT JOIN @SumResult r ON c.URLReferrer = r.URLReferrer AND  r.DeviceType = c.DeviceType 
		LEFT JOIN #memberStats m ON c.URLReferrer = m.URLReferrer AND  m.DeviceType = c.DeviceType  
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd
		AND (c.DeviceType = @DeviceType OR @DeviceType = -1)

	DROP TABLE #memberStats
END
GO