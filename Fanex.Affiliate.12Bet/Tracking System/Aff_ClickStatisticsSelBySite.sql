ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelBySite] 
	@AffID INT
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@DeviceType TINYINT = 0
	,@TotalClicks INT = 0 OUTPUT
	,@UniqueClicks INT = 0 OUTPUT
	,@TotalSignUps INT = 0 OUTPUT
	,@TotalFDMs INT = 0 OUTPUT
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
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
		DomainReferrer NVARCHAR(300)
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
	SELECT md.DomainReferrer
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
	GROUP BY md.DomainReferrer
		,md.DeviceType

	--megre member signup & FDM result
	SELECT r.DomainReferrer
		,r.TotalClick
		,r.UniqueClick
		,ISNULL(m.Signups, 0) AS Signups
		,ISNULL(m.FDM, 0) AS FDM
	FROM @Result r
		LEFT JOIN (
		SELECT *
		FROM #memberStats
		WHERE DeviceType = @DeviceType
		) m ON r.DomainReferrer = m.DomainReferrer

	--sum total click & unique click
	SELECT @TotalClicks = SUM(TotalClick)
		,@UniqueClicks = SUM(UniqueClick)
	FROM @Result

	--sum total signup & fdm
	SELECT @TotalSignUps = ISNULL(SUM(m.Signups), 0)
		,@TotalFDMs = ISNULL(SUM(m.FDM), 0)
	FROM #memberStats m

	DROP TABLE #memberStats

	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNetView]
GO


