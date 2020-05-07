/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelBySite] 
	@AffID INT
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType TINYINT = 0
	,@TotalClicks INT = 0 OUTPUT
	,@UniqueClicks INT = 0 OUTPUT
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS

/*  
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Report click statistics by Referrer site

	Revisions:  
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
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
			@ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120)
			
	DECLARE @ArchiveDate SMALLDATETIME
	SELECT	@ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum (NOLOCK)
	SELECT  @ArchiveDate = ISNULL(@ArchiveDate, DATEADD(DAY, -1, @FromDate))
	
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
		INSERT INTO @Result (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM dbo.ClickStatistics c WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND [Date] > @ArchiveDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType, [Date]
	END

	IF @FromDate <= @ArchiveDate
	BEGIN
		INSERT INTO @Result (DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM dbo.ClickStatisticsSum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND [Date] <= @ArchiveDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType
	END

	INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM, Sort)
	SELECT ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0), SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 0
	FROM @Result
	GROUP BY ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0)
	-- End TotalClick, UniqueClick --

	-- Signups, FDM --
	INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(md.DomainReferrer, 'none')	AS DomainReferrer,
		ISNULL(md.DeviceType, 0)			AS DeviceType,
		0									AS TotalClick,
		0									AS UniqueClick,
		COUNT(CASE WHEN mi.RegisteredDate >= @FromDate AND mi.RegisteredDate < @ToDate THEN 1 ELSE NULL END) AS Signups,
		COUNT(CASE WHEN mi.CreatedDate >= @FromDate AND mi.CreatedDate < @ToDate THEN 1 ELSE NULL END) AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.CustId = mi.CustId
	WHERE mi.AffId = @AffID
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.CustId = mi.CustId
				AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
		)
	GROUP BY
		ISNULL(md.DomainReferrer, 'none'),
		ISNULL(md.DeviceType, 0)
	-- End Signups, FDM --

	-- Return data --
	SELECT
		DomainReferrer,
		SUM(TotalClick)		AS TotalClick,
		SUM(UniqueClick)	AS UniqueClick,
		SUM(Signups)		AS Signups,
		SUM(FDM)			AS FDM
	FROM #tmpResult
	WHERE DeviceType = @DeviceType
	GROUP BY DomainReferrer, Sort
	ORDER BY Sort

	SELECT	@TotalClicks = SUM(TotalClick), @UniqueClicks = SUM(UniqueClick)
	FROM	@Result
	WHERE	DeviceType = @DeviceType

	SELECT	@TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM	#tmpResult
	WHERE	DeviceType = @DeviceType

	DROP TABLE #tmpResult
END
GO