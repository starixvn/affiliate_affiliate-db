ALTER PROCEDURE [dbo].[Task_Aff_MonthlySummaryClickRate] 
	@date SMALLDATETIME
AS
/*
  Task to summary Click Statistics Monthly
  Writer : Peter
  Date : 2009/05/04
  DB: DB052.Affiliate_12BET
  Revisions:	
		- bobby@20140613: format code
*/
BEGIN
	SET NOCOUNT ON

	SELECT @date = convert(VARCHAR(10), @date, 120)

	IF (
			EXISTS (
				SELECT 1
				FROM ClickStatisticsSum(NOLOCK)
				WHERE datediff(mm, @date, [Date]) = 0
				)
			)
	BEGIN
		RETURN
	END

	--Summary for Daily by TrackingID and Date
	INSERT INTO ClickStatisticsSum (
		AffID
		,TrackingID
		,[Date]
		,TotalClick
		,UniqueClick
		,IsForMonth
		)
	SELECT a.AffID
		,t.TrackingID
		,t.[Date]
		,t.TotalClick
		,t.UniqueClick
		,t.IsForMonth
	FROM (
		SELECT TrackingID
			,[Date]
			,sum(1) AS TotalClick
			,count(DISTINCT IP) AS UniqueClick
			,0 AS IsForMonth
		FROM ClickStatistics(NOLOCK)
		WHERE datediff(mm, @date, DATE) = 0
		GROUP BY TrackingID
			,DATE
		) t
		INNER JOIN TrackingCode a(NOLOCK)
		ON a.TrackingID = t.TrackingID

	--Summary for Monthly by TrackingID -each TrackingID will have one row for this month
	INSERT INTO ClickStatisticsSum (
		AffID
		,TrackingID
		,[Date]
		,TotalClick
		,UniqueClick
		,IsForMonth
		)
	SELECT a.AffID
		,t.TrackingID
		,t.[Date]
		,t.TotalClick
		,t.UniqueClick
		,t.IsForMonth
	FROM (
		SELECT TrackingID
			,cast(year([Date]) AS VARCHAR(6)) + '-' + cast(month([Date]) AS VARCHAR(2)) + '-01' AS DATE
			,sum(1) AS TotalClick
			,count(DISTINCT IP) AS UniqueClick
			,1 AS IsForMonth
		FROM ClickStatistics(NOLOCK)
		WHERE datediff(mm, @date, DATE) = 0
		GROUP BY TrackingID
			,month([Date])
			,year([Date])
		) t
		INNER JOIN TrackingCode a(NOLOCK)
		ON a.TrackingID = t.TrackingID

	--Summary for Daily All
	INSERT INTO ClickStatisticsSum (
		AffID
		,TrackingID
		,[Date]
		,TotalClick
		,UniqueClick
		,IsForMonth
		)
	SELECT a.AffID
		,0 AS TrackingID
		,s.[Date]
		,sum(1) AS TotalClick
		,count(DISTINCT s.IP) AS UniqueClick
		,0 AS IsForMonth
	FROM ClickStatistics s(NOLOCK)
		INNER JOIN TrackingCode a(NOLOCK)
		ON a.TrackingID = s.TrackingID
	WHERE datediff(mm, @date, s.DATE) = 0
	GROUP BY a.AffID
		,s.DATE

	--Summary for Monthly All
	INSERT INTO ClickStatisticsSum (
		AffID
		,TrackingID
		,[Date]
		,TotalClick
		,UniqueClick
		,IsForMonth
		)
	SELECT a.AffID
		,0 AS TrackingID
		,cast(year(s.DATE) AS VARCHAR(6)) + '-' + cast(month(s.DATE) AS VARCHAR(2)) + '-01' AS DATE
		,sum(1) AS TotalClick
		,count(DISTINCT s.IP) AS UniqueClick
		,1 AS IsForMonth
	FROM ClickStatistics s(NOLOCK)
		INNER JOIN TrackingCode a(NOLOCK)
		ON a.TrackingID = s.TrackingID
	WHERE datediff(mm, @date, s.DATE) = 0
	GROUP BY a.AffID
		,month(s.DATE)
		,year(s.DATE)

	INSERT INTO ClickStatistics_bk
	SELECT *
	FROM ClickStatistics
	WHERE datediff(mm, @date, DATE) = 0

	DELETE ClickStatistics
	WHERE datediff(mm, @date, DATE) = 0
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlySummaryClickRate] TO [vnteam]
