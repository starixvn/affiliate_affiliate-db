ALTER PROCEDURE [dbo].[AffAdmin_ClickStatisticsSelByPage] 
	@AffID INT
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@SportCode VARCHAR(200) = NULL
	,@LanguageCode VARCHAR(100) = NULL
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
	-20131230:Bobby: change to ClickStatistics & ClickStatistics_bk
	-20140327:Bobby: fixbug https://redmine.nexcel.vn/issues/13595
	-20140509:Bobby: update UniqueClick by date
	-20141022:Bobby: Add filtering by Sport code and LanguageCode
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @SportCodeTable TABLE (SportCode VARCHAR(20))

	INSERT INTO @SportCodeTable
	SELECT CAST(val AS VARCHAR(20))
	FROM [dbo].[strSplit](@SportCode, ',')

	DECLARE @LanguageCodeTable TABLE (LanguageCode VARCHAR(20))

	INSERT INTO @LanguageCodeTable
	SELECT CAST(val AS VARCHAR(20))
	FROM [dbo].[strSplit](@LanguageCode, ',')

	DECLARE @Result AS TABLE (
		SportCode VARCHAR(50)
		,LanguageCode VARCHAR(10)
		,TotalClick INT
		,UniqueClick INT
		,Signups INT
		,FDM INT
		)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatisticsSum
			)

	SELECT @LastDateSum = isnull(@LastDateSum, dateadd(d, - 1, @FromDate))
		,@FromDate = convert(VARCHAR(10), @FromDate, 120)
	
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

	IF (@FromDate > @LastDateSum) --get from main table
	BEGIN
		WITH clickStats
		AS (
			SELECT SportCode
				,LanguageCode
				,Date AS DateClick
				,SUM(ClickCount) AS TotalClick
				,COUNT(DISTINCT IP) AS UniqueClick
				,SUM(ISNULL(m.Signups, 0)) Signups
				,SUM(ISNULL(m.FDM, 0)) FDM
			FROM dbo.ClickStatistics c WITH (NOLOCK)
				LEFT JOIN #memStatsInfo m 
				ON m.clickId = c.clickId
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY SportCode
				,LanguageCode
				,[Date]
		)
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,SUM(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END
	ELSE IF (@ToDate < @LastDateSum) --get from summary table
	BEGIN
		WITH clickStats
		AS (
			SELECT SportCode
				,LanguageCode
				,Date AS DateClick
				,SUM(TotalClick) AS TotalClick
				,SUM(UniqueClick) AS UniqueClick
				,SUM(TotalSignup) AS Signups
				,SUM(TotalDeposit) AS FDM
			FROM ClickStatisticsSum c WITH(NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY SportCode
				,LanguageCode
				,[Date]
		)
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,SUM(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		WITH clickStats
		AS (
			SELECT SportCode
				,LanguageCode
				,Date AS DateClick
				,SUM(ClickCount) AS TotalClick
				,COUNT(DISTINCT IP) AS UniqueClick
				,SUM(ISNULL(m.Signups, 0)) Signups
				,SUM(ISNULL(m.FDM, 0)) FDM
			FROM dbo.ClickStatistics c WITH (NOLOCK)
				LEFT JOIN #memStatsInfo m 
				ON m.clickId = c.clickId
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY SportCode
				,LanguageCode
				,[Date]

			UNION
			SELECT SportCode
				,LanguageCode
				,Date AS DateClick
				,SUM(TotalClick) AS TotalClick
				,SUM(UniqueClick) AS UniqueClick
				,SUM(TotalSignup) AS Signups
				,SUM(TotalDeposit) AS FDM
			FROM ClickStatisticsSum c WITH(NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY SportCode
				,LanguageCode
				,[Date]
		)
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,SUM(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END

	DROP TABLE #memStatsInfo

	SELECT r.*
		,ISNULL(lan.LanguageName, 'N/A') AS LanguageName
	FROM @Result AS r
		INNER JOIN @LanguageCodeTable lf
		ON r.LanguageCode = lf.LanguageCode
		INNER JOIN @SportCodeTable sc
		ON r.SportCode = sc.SportCode
		LEFT JOIN dbo.[Language] AS lan WITH (NOLOCK)
		ON r.LanguageCode = lan.LanguageID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [vnteam]
GO