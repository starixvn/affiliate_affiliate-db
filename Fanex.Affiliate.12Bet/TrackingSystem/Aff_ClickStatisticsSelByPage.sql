USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage] 
	@AffID INT
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@DeviceType TINYINT = 0
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DBAFF12BET.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20140708@Bobby : Apply Device type info
	- 20140805@Bobby : Support sum TotalSignUps & TotalFDMs
	- 20141103@Bobby : Change FromDate & ToDate to DATETIME
	- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @tmpResult TABLE
	(
		SportCode VARCHAR(50),
		LanguageCode VARCHAR(10),
		TotalClick INT,
		UniqueClick INT,
		Signups INT,
		FDM INT
	)

	-- Old Url --

		-- TotalClick, UniqueClick --
	DECLARE @MaxSumDate SMALLDATETIME, @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME
	SELECT  @MaxSumDate = MAX(Date) FROM dbo.ClickStatisticsSum WITH(NOLOCK)

	DECLARE @OldResult TABLE
	(
		TotalClick INT,
		UniqueClick INT,
		Signups INT,
		FDM INT
	)
	
	IF @FromDate < @MaxSumDate
	BEGIN
		SELECT @tmpFromDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @FromDate), 0) -- the first day of next month

		IF @ToDate > @MaxSumDate
		BEGIN
			SELECT @tmpToDate = @MaxSumDate
		END
		ELSE
		BEGIN
			SELECT @tmpToDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @ToDate)-1, -1) -- the last day of previous month
		END

		INSERT INTO @OldResult
		SELECT
			SUM(TotalClick),
			SUM(UniqueClick),
			0 AS Signups,
			0 AS FDM
		FROM dbo.ClickStatisticsSum WITH(NOLOCK)
		WHERE Date BETWEEN @tmpFromDate AND @tmpToDate
			AND IsForMonth = 1
			AND TrackingID = 0 -- sum for months
			AND AffID = @AffID

		IF @FromDate < @tmpFromDate
		BEGIN
			INSERT INTO @OldResult
			SELECT
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT s.IP) AS UniqueClick,
				0 AS Signups,
				0 AS FDM
			FROM dbo.ClickStatistics s WITH(NOLOCK)
			WHERE s.Date >= @FromDate AND s.Date < @tmpFromDate
				AND EXISTS (SELECT 1 FROM dbo.TrackingCode t WITH(NOLOCK)
							WHERE t.AffID = @AffID AND t.TrackingID = s.TrackingID)
		END

		IF @tmpToDate < @ToDate
		BEGIN
			INSERT INTO @OldResult
			SELECT
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT s.IP) AS UniqueClick,
				0 AS Signups,
				0 AS FDM
			FROM dbo.ClickStatistics s WITH(NOLOCK)
			WHERE s.Date > @tmpToDate AND s.Date <= @ToDate
				AND EXISTS (SELECT 1 FROM dbo.TrackingCode t WITH(NOLOCK)
							WHERE t.AffID = @AffID AND t.TrackingID = s.TrackingID)
		END
	END
		-- End TotalClick, UniqueClick --

		-- Signups, FDM --
	INSERT INTO @OldResult
	SELECT
		0 AS TotalClick,
		0 AS UniqueClick,
		COUNT(1) AS Signups,
		COUNT(IBCCustID) AS FDM
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId
		AND CreatDate >= @FromDate AND CreatDate < DATEADD(DAY, 1, @ToDate)
		-- End Signups, FDM --
	
	-- End Old Url

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
	CREATE TABLE #memberStats
	(
		SportCode		VARCHAR(50),
		LanguageCode	VARCHAR(10),
		DeviceType		TINYINT,
		Signups			BIGINT,
		FDM				BIGINT
	)

	;WITH memberStats AS (

		-- sign-up
		SELECT
			SportCode,
			LanguageCode,
			DeviceType,
			COUNT(1) AS Signups,
			0 AS FDM
		FROM dbo.MemberClickDetail WITH (NOLOCK)
		WHERE CreatedDate BETWEEN @FromDate AND @ToDate
			AND AffId = @AffID
			AND SportCode = ISNULL(@SportCode, SportCode)
			AND LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		GROUP BY
			SportCode,
			LanguageCode,
			DeviceType

		UNION ALL

		-- fdm
		SELECT
			ISNULL(md.SportCode, 'none') AS SportCode,
			ISNULL(md.LanguageCode, 'none') AS LanguageCode,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			0 AS Signups,
			COUNT(mi.IBCCustID) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND (@SportCode IS NULL OR ISNULL(SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(LanguageCode, 'none') = @LanguageCode)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.IBCCustID = mi.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY
			ISNULL(md.SportCode, 'none'),
			ISNULL(md.LanguageCode, 'none'),
			ISNULL(md.DeviceType, 0)
	)
	INSERT INTO #memberStats (SportCode, LanguageCode, DeviceType, Signups, FDM)
	SELECT SportCode, LanguageCode, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY SportCode, LanguageCode, DeviceType

	--megre member signup & FDM result	
	;WITH CTE_SportCode_LanguageCode AS
	(
		SELECT DISTINCT SportCode, LanguageCode
		FROM (
			SELECT SportCode, LanguageCode FROM @Result
			UNION ALL
			SELECT SportCode, LanguageCode FROM #memberStats WHERE DeviceType = @DeviceType
		) A
	)
	,CTE_Result AS
	(
		SELECT
			c.SportCode,
			c.LanguageCode,
			ISNULL(r.TotalClick, 0) AS TotalClick,
			ISNULL(r.UniqueClick, 0) AS UniqueClick,
			ISNULL(m.Signups, 0) AS Signups,
			ISNULL(m.FDM, 0) AS FDM
		FROM CTE_SportCode_LanguageCode c
			LEFT JOIN @Result r ON r.SportCode = c.SportCode AND r.LanguageCode = c.LanguageCode
			LEFT JOIN #memberStats m ON m.SportCode = c.SportCode AND m.LanguageCode = c.LanguageCode
	)
	INSERT INTO @tmpResult
	SELECT
		SportCode,
		LanguageCode,
		TotalClick,
		UniqueClick,
		Signups,
		FDM
	FROM CTE_Result
	
	-- Old Url
	UNION ALL
	SELECT
		SportCode,
		LanguageCode,
		CASE WHEN TotalClick < 0 THEN 0 ELSE TotalClick END AS TotalClick,
		CASE WHEN UniqueClick < 0 THEN 0 ELSE UniqueClick END AS UniqueClick,
		CASE WHEN Signups < 0 THEN 0 ELSE Signups END AS Signups,
		CASE WHEN FDM < 0 THEN 0 ELSE FDM END AS FDM
	FROM (
		SELECT
			'Old URL' AS SportCode,
			'none' AS LanguageCode,
			SUM(TotalClick) AS TotalClick,
			SUM(UniqueClick) AS UniqueClick,
			SUM(Signups) AS Signups,
			SUM(FDM) AS FDM
		FROM (
			SELECT
				-SUM(TotalClick) AS TotalClick,
				-SUM(UniqueClick) AS UniqueClick,
				-SUM(Signups) AS Signups,
				-SUM(FDM) AS FDM
			FROM CTE_Result
			UNION ALL
			SELECT
				SUM(TotalClick) AS TotalClick,
				SUM(UniqueClick) AS UniqueClick,
				SUM(Signups) AS Signups,
				SUM(FDM) AS FDM
			FROM @OldResult
		) A
	) B
	WHERE @DeviceType = 0

	IF (SELECT COUNT(1) FROM @tmpResult) = 1
	BEGIN
		SELECT * FROM @tmpResult
		WHERE 1 = 0
	END
	ELSE
	BEGIN
		SELECT * FROM @tmpResult
	END

	--sum total signup & fdm
	SELECT @TotalSignUps = ISNULL(SUM(m.Signups), 0)
		,@TotalFDMs = ISNULL(SUM(m.FDM), 0)
	FROM #memberStats m

	DROP TABLE #memberStats
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