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
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result AS TABLE (
		UrlReferrer NVARCHAR(300)
		,TotalClick INT
		,UniqueClick INT
		)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatistics1Sum (NOLOCK)
			)
		,@FromDate = convert(VARCHAR(10), @FromDate, 120)
		,@ToDate = dbo.Aff_GetEndDate(@ToDate)

	SELECT @LastDateSum = isnull(@LastDateSum, dateadd(d, - 1, @FromDate))

	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY URLReferrer
				,[Date]
			) AS t
		GROUP BY URLReferrer
	END
	ELSE IF (@LastDateSum > @ToDate) --get from bk table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND ( 
					(@DeviceType = 0 AND (c.DeviceType = @DeviceType OR c.DeviceType IS NULL))
					OR 
					(@DeviceType = 1 AND c.DeviceType = @DeviceType)
				)
			GROUP BY URLReferrer
				,[Date]
			) AS t
		GROUP BY URLReferrer
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND ( 
					(@DeviceType = 0 AND (c.DeviceType = @DeviceType OR c.DeviceType IS NULL))
					OR 
					(@DeviceType = 1 AND c.DeviceType = @DeviceType)
				)
			GROUP BY URLReferrer
				,[Date]
			
			UNION ALL
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY URLReferrer
				,[Date]
			) tmp
		GROUP BY URLReferrer
	END

	--count nrows
	SELECT @NRows = count(1)
	FROM @Result

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1
		
	-- count stats Singups & FDM info
	
	CREATE TABLE #memberStats
	(
		URLReferrer NVARCHAR(600),
		Signups		BIGINT,
		FDM			BIGINT
	)
	
	;WITH memberStats AS (

		-- sign-up
		SELECT
			URLReferrer,
			COUNT(1) AS Signups,
			0 AS FDM
		FROM dbo.MemberClickDetail WITH (NOLOCK)
		WHERE CreatedDate BETWEEN @FromDate AND @ToDate
			AND AffId = @AffID
			AND DeviceType = @DeviceType
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY URLReferrer

		UNION ALL

		-- fdm
		SELECT
			ISNULL(md.URLReferrer, 'none') AS URLReferrer,
			0 AS Signups,
			COUNT(mi.IBCCustID) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND ISNULL(md.DeviceType, 0) = @DeviceType
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.IBCCustID = mi.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY ISNULL(md.URLReferrer, 'none')
	)
	INSERT INTO #memberStats (URLReferrer, Signups, FDM)
	SELECT URLReferrer, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY URLReferrer

	;WITH CTE_UrlReferrer AS
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY URLReferrer) AS TheCount,
			URLReferrer
		FROM (
			SELECT DISTINCT URLReferrer
			FROM (
				SELECT TOP (@RowEnd) URLReferrer FROM @Result ORDER BY URLReferrer
				UNION ALL
				SELECT TOP (@RowEnd) URLReferrer FROM #memberStats ORDER BY URLReferrer
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
		LEFT JOIN @Result r ON c.URLReferrer = r.URLReferrer
		LEFT JOIN #memberStats m ON c.URLReferrer = m.URLReferrer
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd

	DROP TABLE #memberStats
END
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbDownlineNet]
GO



