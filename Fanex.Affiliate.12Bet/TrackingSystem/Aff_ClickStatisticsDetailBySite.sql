/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
	@AffID INT
	,@Domain NVARCHAR(300) = NULL
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType TINYINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS

/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DBAFF12BET.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20140708@Bobby : Apply Device type info
	- 20140801@Bobby : Update checking DeviceType in ClickStatistics1_bk
	- 20141103@Bobby : Update checking DeviceType in ClickStatistics1_bk (change AND to OR)
	- 20160327@Bobby : #54942 - Correct time range
	- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
	- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result TABLE
	(
		UrlReferrer		NVARCHAR(300),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT
	)

	SELECT	@LastDateSum =  MAX(DATE) FROM ClickStatistics1Sum (NOLOCK)

	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120),
			@ToDate = dbo.Aff_GetEndDate(@ToDate)

	SELECT @LastDateSum = ISNULL(@LastDateSum, DATEADD(DAY, -1, @FromDate))

	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType, [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END
	ELSE IF (@LastDateSum > @ToDate) --get from bk table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0), [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0), [Date]

			UNION ALL
			SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType, [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END

	--count nrows
	SELECT @NRows = COUNT(1) FROM (SELECT URLReferrer FROM @Result WHERE DeviceType = @DeviceType GROUP BY URLReferrer) AS r

	IF ISNULL(@NRows, 0) = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1
		
	-- count stats Singups & FDM info
	
	CREATE TABLE #memberStats
	(
		URLReferrer NVARCHAR(600),
		DeviceType	TINYINT,
		Signups		BIGINT,
		FDM			BIGINT
	)

	DECLARE @tmp TABLE (ClickID BIGINT)
	INSERT INTO @tmp (ClickID)
	SELECT ISNULL(ClickID, 0)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH(NOLOCK)
	WHERE creatdate BETWEEN @FromDate AND @ToDate
		AND AffiliateID = @AffID
	
	;WITH memberStats AS (

		-- sign-up
		SELECT
			ISNULL(URLReferrer, 'none')		AS URLReferrer,
			ISNULL(DeviceType, 0)			AS DeviceType,
			COUNT(1)						AS Signups,
			0								AS FDM
		FROM @tmp tmp
			LEFT JOIN dbo.ClickStatistics1 c WITH (NOLOCK) ON tmp.ClickID = c.ClickID
		WHERE DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY
			ISNULL(URLReferrer, 'none'),
			ISNULL(DeviceType, 0)

		UNION ALL

		-- fdm
		SELECT
			ISNULL(md.URLReferrer, 'none') AS URLReferrer,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			0 AS Signups,
			COUNT(mi.IBCCustID) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.IBCCustID = mi.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY ISNULL(md.URLReferrer, 'none'), ISNULL(md.DeviceType, 0)
	)
	INSERT INTO #memberStats (URLReferrer, DeviceType, Signups, FDM)
	SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY URLReferrer, DeviceType

	;WITH CTE_UrlReferrer AS
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY URLReferrer) AS TheCount,
			URLReferrer
		FROM (
			SELECT DISTINCT URLReferrer
			FROM (
				SELECT TOP (@RowEnd) URLReferrer FROM @Result WHERE DeviceType = @DeviceType ORDER BY URLReferrer
				UNION ALL
				SELECT TOP (@RowEnd) URLReferrer FROM #memberStats WHERE DeviceType = @DeviceType ORDER BY URLReferrer
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
		LEFT JOIN @Result r ON c.URLReferrer = r.URLReferrer AND r.DeviceType = @DeviceType
		LEFT JOIN #memberStats m ON c.URLReferrer = m.URLReferrer AND m.DeviceType = @DeviceType
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd

	DROP TABLE #memberStats
END
GO