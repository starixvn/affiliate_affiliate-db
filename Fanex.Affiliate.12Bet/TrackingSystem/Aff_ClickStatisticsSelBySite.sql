/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelBySite] 
	@AffID 			INT
	,@CountryCodes 	NVARCHAR(MAX)
	,@FromDate 		DATETIME
	,@ToDate 		DATETIME
	,@DeviceType 	TINYINT = 0
	,@TotalClicks 	INT = 0 OUTPUT
	,@UniqueClicks 	INT = 0 OUTPUT
	,@TotalSignUps 	INT = 0 OUTPUT
	,@TotalFDMs 	INT = 0 OUTPUT
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
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20220919@Eddie: Add Country info [RedmineID: #176390]
	
	Param's Explanation:
		- @CountryCodes: '-,AL,AR,...'
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult (CountryCode VARCHAR(2), DomainReferrer	NVARCHAR(300), DeviceType TINYINT, TotalClick INT, UniqueClick INT, Signups INT, FDM INT)
	
	DECLARE @Result TABLE (CountryCode VARCHAR(2), DomainReferrer NVARCHAR(300), DeviceType	TINYINT, TotalClick	INT, UniqueClick INT)

	DECLARE @BeginRegenData SMALLDATETIME, @LastDateSum DATETIME

	SELECT @BeginRegenData = SValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_OldClickStatisticsDate'

	SELECT @LastDateSum = MAX(DATE) FROM ClickStatistics1Sum WITH(NOLOCK)

	SELECT @FromDate = FORMAT(@FromDate, 'yyyy-MM-dd'), @ToDate = DATEADD(SECOND, -1, DATEADD(MONTH, 1, FORMAT(@ToDate, 'yyyy-MM-01')))

	IF (@LastDateSum < @FromDate) 
	BEGIN
		INSERT INTO @Result(CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT Country, DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT Country, DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND ( ',' + @CountryCodes + ',' LIKE '%,' + Country + ',%')
			GROUP BY Country, DomainReferrer, DeviceType, [Date]
		)AS n
		GROUP BY Country, DomainReferrer, DeviceType
	END
	ELSE IF (@LastDateSum > @ToDate) 
	BEGIN
		INSERT INTO @Result(CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT CountryCode, DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT CountryCode, DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
			FROM ClickStatistics1Sum WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND ( ',' + @CountryCodes + ',' LIKE '%,' + CountryCode + ',%')
			GROUP BY CountryCode, DomainReferrer, DeviceType
		)AS n
		GROUP BY CountryCode, DomainReferrer, DeviceType
	END
	ELSE 
	BEGIN
		INSERT INTO @Result(CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT CountryCode, DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT CountryCode, DomainReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
			FROM ClickStatistics1Sum WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @LastDateSum
				AND AffId = @AffID
				AND ( ',' + @CountryCodes + ',' LIKE '%,' + CountryCode + ',%')
			GROUP BY CountryCode, DomainReferrer, DeviceType, [Date]
			UNION ALL
			SELECT Country AS CountryCode, DomainReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum AND @ToDate
				AND AffId = @AffID
				AND ( ',' + @CountryCodes + ',' LIKE '%,' + Country + ',%')
			GROUP BY Country, DomainReferrer, DeviceType, [Date]
		)AS n
		GROUP BY CountryCode, DomainReferrer, DeviceType
	END

	INSERT INTO #tmpResult (CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT 
		CountryCode
		,ISNULL(DomainReferrer, 'none') AS DomainReferrer
		,ISNULL(DeviceType, 0) 			AS DeviceType
		,SUM(ISNULL(TotalClick, 0)) 	AS TotalClick
		,SUM(ISNULL(UniqueClick, 0)) 	AS UniqueClick
		,0 								AS Signups
		,0 								AS FDM
	FROM @Result
	GROUP BY 
		CountryCode
		,ISNULL(DomainReferrer, 'none')
		,ISNULL(DeviceType, 0)

	-- Signups, FDM --
	INSERT INTO #tmpResult (CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) AS CountryCode
		,ISNULL(md.DomainReferrer, 'none') AS DomainReferrer
		,ISNULL(md.DeviceType, 0) 		   AS DeviceType
		,0 		  						   AS TotalClick
		,0 		  						   AS UniqueClick
		,0 		  						   AS Signups
		,COUNT(1) 						   AS FDM
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID
		LEFT JOIN ClickStatistics1 c 	   WITH (NOLOCK) ON c.ClickID    = md.ClickID
		LEFT JOIN ClickStatistics1_bk csk  WITH (NOLOCK) ON csk.ClickID  = md.ClickID
	WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
		AND mi.AffId = @AffID
		AND NOT EXISTS (SELECT 1 
						FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustID = mi.IBCCustID 
						  AND mr.RemovedDate BETWEEN @FromDate AND @ToDate)
		AND (',' + @CountryCodes + ',' LIKE '%,' + ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) + ',%')
	GROUP BY
		ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END)
		,ISNULL(md.DomainReferrer, 'none')
		,ISNULL(md.DeviceType, 0)

	DECLARE @tmp TABLE (ClickID BIGINT)

	INSERT INTO @tmp (ClickID)
	SELECT ISNULL(ClickID, 0)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE creatdate BETWEEN @FromDate AND @ToDate 
		AND AffiliateID = @AffID

	INSERT INTO #tmpResult (CountryCode, DomainReferrer, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT
		ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) AS CountryCode
		,COALESCE(c.DomainReferrer, csk.DomainReferrer, 'none')	AS DomainReferrer
		,COALESCE(c.DeviceType, csk.DeviceType, 0) 				AS DeviceType
		,0 														AS TotalClick
		,0 														AS UniqueClick
		,COUNT(1) 												AS Signups
		,0 														AS FDM
	FROM @tmp tmp
		LEFT JOIN dbo.ClickStatistics1 c 	  WITH (NOLOCK) ON tmp.ClickID = c.ClickID
		LEFT JOIN dbo.ClickStatistics1_bk csk WITH (NOLOCK) ON tmp.ClickID = csk.ClickID
	GROUP BY
		ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END)
		,COALESCE(c.DomainReferrer, csk.DomainReferrer, 'none')
		,COALESCE(c.DeviceType, csk.DeviceType, 0)

	SELECT @TotalClicks = SUM(TotalClick), @UniqueClicks = SUM(UniqueClick)
	FROM @Result 
	WHERE DeviceType = @DeviceType

	SELECT @TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM #tmpResult
	WHERE DeviceType = @DeviceType

	SELECT
		tr.DomainReferrer 	 AS SiteURLS
		,tr.CountryCode 	 AS CountryCode
		,CASE WHEN tr.CountryCode <> '-' THEN c.CountryName ELSE 'Unknown' END AS Country
		,SUM(tr.TotalClick)  AS TotalClick
		,SUM(tr.UniqueClick) AS UniqueClick
		,SUM(tr.Signups) 	 AS Signups
		,SUM(tr.FDM) 		 AS FDM
		,CASE WHEN tr.CountryCode <> '-' THEN 0 ELSE 1 END AS ordered 
	FROM #tmpResult tr
		LEFT JOIN Country c WITH (NOLOCK) ON c.CountryCode = tr.CountryCode
	WHERE tr.DeviceType = @DeviceType
	GROUP BY 
		tr.DomainReferrer
		,tr.CountryCode
		,CASE WHEN tr.CountryCode <> '-' THEN c.CountryName ELSE 'Unknown' END
	ORDER BY tr.DomainReferrer, ordered, Country

	DROP TABLE #tmpResult
END
GO