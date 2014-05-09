ALTER PROCEDURE [dbo].[AffAdmin_ClickStatisticsDetail] 
	@AffID INT
	,@Domain NVARCHAR(300) = NULL
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	-20131230:Bobby: change to ClickStatistics & ClickStatistics_bk
	-20140327:Bobby: fixbug https://redmine.nexcel.vn/issues/13595
	-20140509:Bobby: update UniqueClick by date
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result AS TABLE (
		UrlReferrer NVARCHAR(300)
		,TotalClick INT
		,UniqueClick INT
		,Signups INT
		,FDM INT
		)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatisticsSum
			)
		,@FromDate = convert(VARCHAR(10), @FromDate, 120)

	SELECT @LastDateSum = ISNULL(@LastDateSum, dateadd(d, - 1, @FromDate))


	-- member stats info
	SELECT m.clickId
		,SUM(CASE 
				WHEN m.RegisteredDate IS NOT NULL THEN 1
				ELSE 0
				END) AS Signups
		,SUM(CASE 
				WHEN m.CreatedDate IS NOT NULL THEN 1
				ELSE 0
				END) AS FDM
	INTO #memStatsInfo
	FROM MemberInfo m WITH (NOLOCK)
	WHERE AffId = @AffID
		AND RegisteredDate BETWEEN @FromDate AND @ToDate
		OR CreatedDate BETWEEN @FromDate AND @ToDate
	GROUP BY ClickID


	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		WITH clickStats
		AS (
			SELECT URLReferrer
			,[Date]
			,SUM(ClickCount) AS TotalClick
			,COUNT(DISTINCT IP) AS UniqueClick
			,SUM(ISNULL(m.Signups, 0)) Signups
			,SUM(ISNULL(m.FDM, 0)) FDM
		FROM ClickStatistics c
			LEFT JOIN #memStatsInfo m 
			ON m.clickId = c.clickId
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND c.AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
		GROUP BY URLReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT URLReferrer
			,SUM(ClickCount) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats
		GROUP BY URLReferrer
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table
	BEGIN
		WITH clickStats
		AS (
			SELECT URLReferrer
			,[Date]
			,SUM(ClickCount) AS TotalClick
			,COUNT(DISTINCT IP) AS UniqueClick
			,SUM(ISNULL(m.Signups, 0)) Signups
			,SUM(ISNULL(m.FDM, 0)) FDM
		FROM ClickStatistics_bk c
			LEFT JOIN #memStatsInfo m 
			ON m.clickId = c.clickId
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND c.AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
		GROUP BY URLReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT URLReferrer
			,SUM(ClickCount) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats
		GROUP BY URLReferrer
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		WITH clickAll
		AS 
		(
			SELECT ClickId 
				,[Date]
				,URLReferrer
				,ClickCount
				,IP
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
			UNION
			SELECT ClickId 
				,[Date]
				,URLReferrer
				,LanguageCode
				,ClickCount
				,IP
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
				AND DomainReferrer = ISNULL(@Domain, DomainReferrer)
		)
		,clickStats
		AS (
			SELECT URLReferrer
			,[Date]
			,SUM(ClickCount) AS TotalClick
			,COUNT(DISTINCT IP) AS UniqueClick
			,SUM(ISNULL(m.Signups, 0)) Signups
			,SUM(ISNULL(m.FDM, 0)) FDM
		FROM clickAll c
			LEFT JOIN #memStatsInfo m 
			ON m.clickId = c.clickId
		GROUP BY URLReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT URLReferrer
			,SUM(ClickCount) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats
		GROUP BY URLReferrer
	END

	--count nrows
	SELECT @NRows = COUNT(1)
	FROM @Result

	IF (ISNULL(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT URLReferrer
		,TotalClick
		,UniqueClick
		,Signups
		,FDM
	FROM (
		SELECT TOP (@RowEnd) ROW_NUMBER() OVER (
				ORDER BY URLReferrer
				) AS TheCount
			,*
		FROM @Result
		) x
	WHERE x.TheCount BETWEEN @RowStart AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsDetail] TO [bodbAdminNet]
