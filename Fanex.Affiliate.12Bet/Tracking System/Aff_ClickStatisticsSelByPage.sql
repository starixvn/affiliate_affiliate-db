ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage] 
	@AffID INT
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@DeviceType TINYINT = 0
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20140708@Bobby : Apply Device type info
	- 20140805@Bobby : Support sum TotalSignUps & TotalFDMs
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result AS TABLE (
		SportCode VARCHAR(50)
		,LanguageCode VARCHAR(10)
		,TotalClick INT
		,UniqueClick INT
		)

	SELECT @ToDate = dbo.Aff_GetEndDate(@ToDate)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatistics1Sum
			)

	SELECT @LastDateSum = isnull(@LastDateSum, dateadd(d, - 1, @FromDate))
		,@FromDate = convert(VARCHAR(10), @FromDate, 120)

	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,sum(TotalClick) AS TotalClick
			,Sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT SportCode
				,LanguageCode
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY SportCode
				,LanguageCode
				,[Date] --[Date] in condition to calculate unique click
			) AS tmp
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table
	BEGIN
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM ClickStatistics1Sum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate
				AND @ToDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
			AND DeviceType = @DeviceType
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT SportCode
			,LanguageCode
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT SportCode
				,LanguageCode
				,sum(TotalClick) AS TotalClick
				,sum(UniqueClick) AS UniqueClick
			FROM ClickStatistics1Sum WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @LastDateSum
				AND AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY SportCode
				,LanguageCode
				,[Date]
			
			UNION ALL
			SELECT SportCode
				,LanguageCode
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum
					AND @ToDate
				AND AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY SportCode
				,LanguageCode
				,[Date]
			) tmp
		GROUP BY SportCode
			,LanguageCode
		ORDER BY SportCode
			,LanguageCode
	END

	/**
	count total Signups & FDM info
	*/
	SELECT md.SportCode
		,md.LanguageCode
		,md.DeviceType
		,COUNT(1) AS Signups
		,SUM(CASE 
				WHEN md.IBCCustID IS NOT NULL THEN 1
				ELSE 0
				END) AS FDM
	INTO #memberStats
	FROM dbo.MemberClickDetail md WITH (NOLOCK)
	WHERE md.CreatedDate BETWEEN @FromDate
			AND @ToDate
		AND md.AffId = @AffID
		AND md.SportCode = ISNULL(@SportCode, SportCode)
		AND md.LanguageCode = ISNULL(@LanguageCode, LanguageCode)
	GROUP BY md.SportCode
		,md.LanguageCode
		,md.DeviceType

	--megre member signup & FDM result	
	SELECT r.SportCode
		,r.LanguageCode
		,r.TotalClick
		,r.UniqueClick
		,ISNULL(m.Signups, 0) AS Signups
		,ISNULL(m.FDM, 0) AS FDM
	FROM @Result r
		LEFT JOIN (
		SELECT *
		FROM #memberStats
		WHERE DeviceType = @DeviceType
		) m ON r.SportCode = m.SportCode
		AND r.LanguageCode = m.LanguageCode

	--sum total signup & fdm
	SELECT @TotalSignUps = ISNULL(SUM(m.Signups), 0)
		,@TotalFDMs = ISNULL(SUM(m.FDM), 0)
	FROM #memberStats m

	DROP TABLE #memberStats

	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNetView]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsSelByPage] TO [vnteam]
GO


