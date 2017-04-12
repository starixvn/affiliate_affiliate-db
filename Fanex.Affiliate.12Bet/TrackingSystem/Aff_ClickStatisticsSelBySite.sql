/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/

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

	CREATE TABLE #tmpResult
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT,
		Signups			INT,
		FDM				INT,
		Sort			TINYINT DEFAULT (0)
	)
	
	DECLARE @TrackingCode TABLE
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		IBCCustID		INT,
		TrackingDate	DATETIME,
		IsFDM			BIT,
		IsNew			BIT
	)

	--CREATE TABLE #custInfo (custid INT, creatdate DATETIME)

	-- TotalClick, UniqueClick --
		-- Old --
	DECLARE @MaxSumDate SMALLDATETIME, @tmpFromDate SMALLDATETIME, @tmpToDate SMALLDATETIME
	SELECT  @MaxSumDate = MAX(Date) FROM dbo.ClickStatisticsSum WITH(NOLOCK)

	DECLARE @OldResult TABLE
	(
		TotalClick INT,
		UniqueClick INT
	)

	DECLARE @Result TABLE
	(
		DomainReferrer	NVARCHAR(600),
		DeviceType		TINYINT,
		TotalClick		INT,
		UniqueClick		INT
	)
	
	IF @FromDate < @MaxSumDate
	BEGIN
		IF DAY(@FromDate) = 1
		BEGIN
			SELECT @tmpFromDate = @FromDate
		END
		ELSE
		BEGIN
			SELECT @tmpFromDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, @FromDate), 0) -- the first day of next month
		END

		IF DATEADD(DAY, 1, @ToDate) > @MaxSumDate
		BEGIN
			SELECT @tmpToDate = @MaxSumDate
		END
		ELSE
		BEGIN
			SELECT @tmpToDate = DATEADD(MONTH, DATEDIFF(MONTH, -1, DATEADD(DAY, 1, @ToDate))-1, -1) -- the last day of previous month
		END
		
		INSERT INTO @OldResult
		SELECT
			SUM(TotalClick),
			SUM(UniqueClick)
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
				COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
			WHERE s.Date >= @FromDate AND s.Date < @tmpFromDate
				AND EXISTS (SELECT 1 FROM dbo.TrackingCode t WITH(NOLOCK)
							WHERE t.AffID = @AffID AND t.TrackingID = s.TrackingID)
			GROUP BY s.Date
		END

		IF @tmpToDate < @ToDate
		BEGIN
			INSERT INTO @OldResult
			SELECT
				COUNT(1) AS TotalClick,
				COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
			WHERE s.Date > @tmpToDate AND s.Date <= @ToDate
				AND EXISTS (SELECT 1 FROM dbo.TrackingCode t WITH(NOLOCK)
							WHERE t.AffID = @AffID AND t.TrackingID = s.TrackingID)
			GROUP BY s.Date
		END
	END
	ELSE
	BEGIN
		INSERT INTO @OldResult
		SELECT
			COUNT(1) AS TotalClick,
			COUNT(DISTINCT s.IP) AS UniqueClick
		FROM dbo.ClickStatistics s WITH(NOLOCK)
		WHERE s.Date >= @FromDate AND s.Date < DATEADD(DAY, 1, @ToDate)
			AND EXISTS (SELECT 1 FROM dbo.TrackingCode t WITH(NOLOCK)
					WHERE t.AffID = @AffID AND t.TrackingID = s.TrackingID)
		GROUP BY s.Date
	END
		-- End Old --

		-- New --
	DECLARE @LastDateSum DATETIME

	SELECT @ToDate = DATEADD(S, -1, DATEADD(M, DATEDIFF(M, 0, DATEADD(M, 1, @ToDate)), 0))

	SELECT @LastDateSum = MAX(DATE) FROM ClickStatistics1Sum WITH(NOLOCK)

	SELECT	@LastDateSum = ISNULL(@LastDateSum, DATEADD(DAY, -1, @FromDate)),
			@FromDate = CONVERT(VARCHAR(10), @FromDate, 120)

	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		INSERT INTO @Result
		SELECT DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM ClickStatistics1 c WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType, [Date]
	END
	ELSE IF (@LastDateSum > @ToDate) --get from summary table
	BEGIN
		INSERT INTO @Result
		SELECT DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM ClickStatistics1Sum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate AND @ToDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM ClickStatistics1Sum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate
				AND @LastDateSum
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType, [Date]
			
		UNION ALL

		SELECT DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
		FROM ClickStatistics1 c WITH (NOLOCK)
		WHERE [Date] BETWEEN @LastDateSum AND @ToDate
			AND AffId = @AffID
		GROUP BY DomainReferrer, DeviceType, [Date]
	END
		-- End New --

	INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM, Sort)
	SELECT 'Old URL', 0, SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 1 FROM @OldResult
	UNION ALL
	SELECT ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0), SUM(ISNULL(TotalClick, 0)), SUM(ISNULL(UniqueClick, 0)), 0, 0, 0 FROM @Result
	GROUP BY ISNULL(DomainReferrer, 'none'), ISNULL(DeviceType, 0)

	-- End TotalClick, UniqueClick --

	-- Signups, FDM --
	/*
	INSERT INTO #custInfo (custid, creatdate)
	SELECT custid, creatdate
	FROM bodb02.dbo.Customer c WITH(NOLOCK)
	WHERE roleid = 1
		AND creatdate BETWEEN @FromDate AND @ToDate
	*/

		-- Old --
	/*
	INSERT INTO @TrackingCode (DomainReferrer, DeviceType, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT 'none', 0, IBCCustID, CreatDate, 0, 0
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId
		AND CreatDate BETWEEN @FromDate AND @ToDate

	INSERT INTO @TrackingCode (DomainReferrer, DeviceType, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT 'none', 0, c.custid, c.creatdate, 1, 0
	FROM #custInfo c
	WHERE EXISTS (SELECT 1 FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer dc WITH (NOLOCK) WHERE dc.AffiliateId = @AffId AND dc.IBCCustID = c.custid)
	*/
		-- End Old --

		-- New --
	INSERT INTO @TrackingCode (DomainReferrer, DeviceType, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT ISNULL(md.DomainReferrer, 'none') AS DomainReferrer, ISNULL(md.DeviceType, 0) AS DeviceType, mi.IBCCustID, mi.CreatedDate, 1, 1
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

	INSERT INTO @TrackingCode (DomainReferrer, DeviceType, IBCCustID, TrackingDate, IsFDM, IsNew)
	SELECT ISNULL(DomainReferrer, 'none') AS DomainReferrer, ISNULL(DeviceType, 0) AS DeviceType, IBCCustID, CreatedDate, 0, 1
	FROM dbo.MemberClickDetail WITH (NOLOCK)
	WHERE CreatedDate BETWEEN @FromDate AND @ToDate
		AND AffId = @AffID
		-- End New --
	
	DELETE t1
	FROM @TrackingCode t1
		INNER JOIN @TrackingCode t2
			ON ISNULL(t1.IBCCustID, 0) = ISNULL(t2.IBCCustID, 0) AND t1.TrackingDate = t2.TrackingDate
				AND t1.IsNew = 0 AND t2.IsNew = 1
				AND t1.IsFDM = t2.IsFDM

	INSERT INTO #tmpResult (DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT DomainReferrer, DeviceType, 0, 0, SUM(CASE WHEN IsFDM = 1 THEN 0 ELSE 1 END) AS Signups, COUNT(CASE WHEN IsFDM = 1 THEN IBCCustID ELSE NULL END) AS FDM
	FROM @TrackingCode
	GROUP BY DomainReferrer, DeviceType
	-- End Signups, FDM --

	-- Return data --
	IF (SELECT COUNT(1) FROM #tmpResult WHERE DomainReferrer <> 'Old URL' AND DeviceType = @DeviceType) = 0
	BEGIN
		DELETE #tmpResult
		WHERE DomainReferrer = 'Old URL'
			AND (ISNULL(TotalClick, 0) = 0 AND ISNULL(UniqueClick, 0) = 0 AND ISNULL(Signups, 0) = 0 AND ISNULL(FDM, 0) = 0)
	END

	SELECT
		DomainReferrer,
		SUM(TotalClick)		AS TotalClick,
		SUM(UniqueClick)	AS UniqueClick,
		SUM(Signups)		AS Signups,
		SUM(FDM)			AS FDM
	FROM #tmpResult
	WHERE DeviceType = @DeviceType
	GROUP BY DomainReferrer, Sort
	ORDER BY Sort

	SELECT	@TotalClicks = SUM(TotalClick), @UniqueClicks = SUM(UniqueClick)
	FROM	@Result
	WHERE	DeviceType = @DeviceType

	SELECT	@TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM	#tmpResult
	WHERE	DeviceType = @DeviceType

	DROP TABLE #tmpResult
END
GO