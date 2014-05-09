ALTER PROCEDURE [dbo].[AffAdmin_ClickStatisticsSelBySite] 
	@AffID INT
	,@FromDate SMALLDATETIME
	,@ToDate SMALLDATETIME
	,@TotalClicks INT = 0 OUTPUT
	,@UniqueClicks INT = 0 OUTPUT
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
		DomainReferrer NVARCHAR(300)
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

	IF (@LastDateSum < @FromDate) --get from main table  
	BEGIN
		WITH clickStats
		AS (
			SELECT DomainReferrer
				,Date AS DateClick
				,sum(ClickCount) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
				,SUM(ISNULL(m.Signups, 0)) Signups
				,SUM(ISNULL(m.FDM, 0)) FDM
			FROM dbo.ClickStatistics c WITH (NOLOCK)
				LEFT JOIN #memStatsInfo m 
				ON m.clickId = c.clickId
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY DomainReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY DomainReferrer
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table  
	BEGIN
		WITH clickStats
		AS (
			SELECT DomainReferrer
				,Date AS DateClick
				,sum(ClickCount) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
				,SUM(ISNULL(m.Signups, 0)) Signups
				,SUM(ISNULL(m.FDM, 0)) FDM
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
				LEFT JOIN #memStatsInfo m 
				ON m.clickId = c.clickId
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			GROUP BY DomainReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY DomainReferrer
	END
	ELSE --@fromdate < @LastDateSum < @ToDate  
	BEGIN
		WITH clickAll
		AS (
			SELECT ClickId 
				,Date
				,DomainReferrer
				,ClickCount
				,IP
			FROM dbo.ClickStatistics c WITH (NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			
			UNION
			SELECT ClickId 
				,Date
				,DomainReferrer
				,ClickCount
				,IP
			FROM dbo.ClickStatistics_bk c WITH (NOLOCK)
			WHERE c.[Date] BETWEEN @FromDate AND @ToDate
				AND c.AffId = @AffID
			)
		,clickStats
		AS (
			SELECT DomainReferrer
				,Date AS DateClick
				,sum(ClickCount) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
				,SUM(ISNULL(m.Signups, 0)) Signups
				,SUM(ISNULL(m.FDM, 0)) FDM
			FROM clickAll c WITH (NOLOCK)
				LEFT JOIN #memStatsInfo m 
				ON m.clickId = c.clickId
			GROUP BY DomainReferrer, [Date]
		)
		INSERT INTO @Result
		SELECT DomainReferrer
			,sum(TotalClick) AS TotalClick
			,SUM(UniqueClick) AS UniqueClick
			,SUM(ISNULL(Signups, 0)) Signups
			,SUM(ISNULL(FDM, 0)) FDM
		FROM clickStats c WITH (NOLOCK)
		GROUP BY DomainReferrer
	END
	
	DROP TABLE #memStatsInfo

	SELECT @TotalClicks = SUM(TotalClick)
		,@UniqueClicks = SUM(UniqueClick)
	FROM @Result

	SELECT *
	FROM @Result
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [bodbAdminNet]
