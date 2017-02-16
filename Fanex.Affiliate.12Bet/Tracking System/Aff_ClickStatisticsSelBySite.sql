USE [Affiliate_12BET]
GO

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
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
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

	IF (@FromDate > @ToDate) RETURN

	DECLARE @tmpResult TABLE
	(
		DomainReferrer NVARCHAR(600),
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

	DECLARE @LastDateSum DATETIME
	
	DECLARE @Result AS TABLE (
		DomainReferrer NVARCHAR(600)
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
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT DomainReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DeviceType = @DeviceType
			GROUP BY DomainReferrer
				,[Date]
			) AS t
		GROUP BY DomainReferrer
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table
	BEGIN
		INSERT INTO @Result
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM ClickStatistics1Sum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate
				AND @ToDate
			AND AffId = @AffID
			AND DeviceType = @DeviceType
		GROUP BY DomainReferrer
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT DomainReferrer
				,sum(TotalClick) AS TotalClick
				,sum(UniqueClick) AS UniqueClick
			FROM ClickStatistics1Sum WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @LastDateSum
				AND AffId = @AffID
				AND DeviceType = @DeviceType
			GROUP BY DomainReferrer
				,[Date]
			
			UNION ALL
			SELECT DomainReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum
					AND @ToDate
				AND AffId = @AffID
				AND DeviceType = @DeviceType
			GROUP BY DomainReferrer
				,[Date]
			) tmp
		GROUP BY DomainReferrer
	END

	/**
	count total Signups & FDM info
	*/
	CREATE TABLE #memberStats
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		Signups			BIGINT,
		FDM				BIGINT
	)

	;WITH memberStats AS (

		-- sign-up
		SELECT
			DomainReferrer,
			DeviceType,
			COUNT(1) AS Signups,
			0 AS FDM
		FROM dbo.MemberClickDetail WITH (NOLOCK)
		WHERE CreatedDate BETWEEN @FromDate AND @ToDate
			AND AffId = @AffID
		GROUP BY
			DomainReferrer,
			DeviceType

		UNION ALL

		-- fdm
		SELECT
			ISNULL(md.DomainReferrer, 'none') AS DomainReferrer,
			ISNULL(md.DeviceType, 0) AS DeviceType,
			0 AS Signups,
			COUNT(mi.IBCCustID) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE
					mr.IBCCustID = mi.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY
			ISNULL(md.DomainReferrer, 'none'),
			ISNULL(md.DeviceType, 0)
	)
	INSERT INTO #memberStats (DomainReferrer, DeviceType, Signups, FDM)
	SELECT DomainReferrer, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY DomainReferrer, DeviceType

	--megre member signup & FDM result
	;WITH CTE_DomainReferrer AS
	(
		SELECT DISTINCT DomainReferrer
		FROM (
			SELECT DomainReferrer FROM @Result
			UNION ALL
			SELECT DomainReferrer FROM #memberStats WHERE DeviceType = @DeviceType
		) A
	)
	,CTE_Result AS
	(
		SELECT
			c.DomainReferrer,
			ISNULL(r.TotalClick, 0) AS TotalClick,
			ISNULL(r.UniqueClick, 0) AS UniqueClick,
			ISNULL(m.Signups, 0) AS Signups,
			ISNULL(m.FDM, 0) AS FDM
		FROM CTE_DomainReferrer c
			LEFT JOIN @Result r ON r.DomainReferrer = c.DomainReferrer
			LEFT JOIN #memberStats m ON m.DomainReferrer = c.DomainReferrer
	)
	INSERT INTO @tmpResult
	SELECT
		DomainReferrer,
		TotalClick,
		UniqueClick,
		Signups,
		FDM
	FROM CTE_Result
	
	-- Old Url
	UNION ALL
	SELECT
		DomainReferrer,
		CASE WHEN TotalClick < 0 THEN 0 ELSE TotalClick END AS TotalClick,
		CASE WHEN UniqueClick < 0 THEN 0 ELSE UniqueClick END AS UniqueClick,
		CASE WHEN Signups < 0 THEN 0 ELSE Signups END AS Signups,
		CASE WHEN FDM < 0 THEN 0 ELSE FDM END AS FDM
	FROM (
		SELECT
			'Old URL' AS DomainReferrer,
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

	--sum total click & unique click
	SELECT @TotalClicks = SUM(TotalClick)
		,@UniqueClicks = SUM(UniqueClick)
	FROM @Result

	--sum total signup & fdm
	SELECT @TotalSignUps = ISNULL(SUM(m.Signups), 0)
		,@TotalFDMs = ISNULL(SUM(m.FDM), 0)
	FROM #memberStats m

	DROP TABLE #memberStats
END
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNetView]
GO