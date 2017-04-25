/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateStatisticsDetail]
	@AffId		INT,
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@IsGetAll	BIT
AS

/*
	Created by: Percy
	Date: 2017-04-11
	DB: DBAFF12BET.Affiliate_12BET
	Task: Get statistics report detail for affiliate - Change formula Active, Dormant, Total and TotalRegistered columns [RedmineID: #74560]
	
	Original: Aff_AffiliateStatisticsDetail
	
	Revisions:
	
	Param's Explanation:
		• @FromDate, @ToDate: date range
		• @IsGetAll: = 1 => get data all date of Affiliate
*/

BEGIN
	SET NOCOUNT ON

	SELECT  @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, DATEDIFF(DAY, 0, @ToDate) + 1, 0))

	DECLARE @Tracking TABLE (TrackingDate SMALLDATETIME, TotalClick INT, UniqueClick INT, Signups INT, FDMs INT, Active INT)

	-- Tracking statistics
	INSERT INTO @Tracking
	SELECT
		Date AS TrackingDate,
		SUM(ISNULL(TotalClick, 0)) AS TotalClick,
		SUM(ISNULL(UniqueClick, 0)) AS UniqueClick,
		0 AS Signups,
		0 AS FDMs,
		0 AS Active
	FROM (
		SELECT
			c.Date,
			COUNT(1) AS TotalClick,
			COUNT(DISTINCT c.IP) AS UniqueClick
		FROM dbo.ClickStatistics1 c WITH (NOLOCK)
		WHERE
			c.Date BETWEEN @FromDate AND @ToDate
			AND c.AffId = @AffId
		GROUP BY c.Date

		UNION ALL
		SELECT
			c.Date,
			SUM(TotalClick) AS TotalClick,
			SUM(UniqueClick) AS UniqueClick
		FROM dbo.ClickStatistics1Sum c WITH (NOLOCK)
		WHERE
			(@IsGetAll = 1 OR c.Date BETWEEN @FromDate AND @ToDate)
			AND c.AffId = @AffId
		GROUP BY c.Date
	) AS A
	GROUP BY Date

	-- FDM/Sigup statistics
	DECLARE @TrackingCode TABLE (TrackingDate DATE, IBCCustID INT, IsFDM BIT)
	
	INSERT INTO @TrackingCode (TrackingDate, IBCCustID, IsFDM)
	SELECT mi.CreatedDate, mi.IBCCustID, 1
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
		AND mi.AffID = @AffId
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE
				mr.IBCCustID = mi.IBCCustID
				AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
		)

	INSERT INTO @TrackingCode (TrackingDate, IBCCustID, IsFDM)
	SELECT md.CreatedDate, md.IBCCustID, 0
	FROM dbo.MemberClickDetail md WITH (NOLOCK)
	WHERE md.CreatedDate BETWEEN @FromDate AND @ToDate
		AND md.AffID = @AffId
	
	INSERT INTO @Tracking
	SELECT CONVERT(DATE, TrackingDate), 0 AS TotalClick, 0 AS UniqueClick, SUM(CASE WHEN IsFDM = 1 THEN 0 ELSE 1 END) AS Signups, SUM(CASE WHEN IsFDM = 0 THEN 0 ELSE 1 END) AS FDMs, 0 AS Active
	FROM @TrackingCode
	GROUP BY TrackingDate

	-- Active statistics
	INSERT INTO @Tracking
	SELECT md.WinlostDate, 0 AS TotalClick, 0 AS UniqueClick, 0 AS Signups, 0 AS FDMs, COUNT(DISTINCT md.IBCCustID) AS Active
	FROM dbo.MemberDaily md WITH(NOLOCK)
	WHERE (@IsGetAll = 1 OR md.WinlostDate BETWEEN @FromDate AND @ToDate)
		AND md.AffId = @AffId
		AND EXISTS (
			SELECT 1 FROM @TrackingCode t WHERE md.IBCCustID = t.IBCCustID AND t.IsFDM = 1 AND md.WinlostDate = t.TrackingDate
		)
	GROUP BY WinlostDate

	-- Return Data
	SELECT
		DATEDIFF(DAY, 0, TrackingDate) AS ForeignKey,
		TrackingDate AS CreatedDate,
		SUM(Active) AS Active,
		SUM(FDMs - Active) AS Dormant,
		SUM(FDMs) AS Total,
		SUM(Signups) AS TotalRegistered,
		SUM(TotalClick) AS TotalClick,
		SUM(UniqueClick) AS UniqueClick
	FROM @Tracking
	GROUP BY DATEDIFF(DAY, 0, TrackingDate), TrackingDate
	ORDER BY DATEDIFF(DAY, 0, TrackingDate), TrackingDate

END