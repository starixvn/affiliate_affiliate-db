/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff,wsv_affv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
	@AffID 			INT
	,@Domain 		NVARCHAR(300) = NULL
	,@CountryCode 	VARCHAR(10)   = NULL
	,@SportCode 	VARCHAR(50)   = NULL
	,@LanguageCode 	VARCHAR(10)   = NULL
	,@FromDate 		DATETIME
	,@ToDate 		DATETIME
	,@DeviceType 	TINYINT = 0
	,@PageSize 		INT = 50
	,@PageIndex 	INT = 1
	,@TotalPages 	INT = 0 OUTPUT
	,@NRows 		INT = 0 OUTPUT
AS

/*  
	Created: 20111005@Johnny  
	Task :   Report click statistics by Referrer site
	DB: DBAFF12BET.Affiliate_12BET  
	Original:  
  
	Revisions:  
		- 20140708@Bobby : Apply Device type info
		- 20140801@Bobby : Update checking DeviceType in ClickStatistics1_bk
		- 20141103@Bobby : Update checking DeviceType in ClickStatistics1_bk (change AND to OR)
		- 20160327@Bobby : #54942 - Correct time range
		- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20220927@Eddie: Add Country info [RedmineID: #176390]
		- 20230214@Eddie: Site and Page are case by case [RedmineID: #177639]
		- 20240321@Eddie: Change Link Server and metadata "bodbAdminNet,bodbDownlineNet" [RedmineID: #202712]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN
	
	DECLARE @BeginRegenData SMALLDATETIME

	SELECT @BeginRegenData = SValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_OldClickStatisticsDate'

	DECLARE @Result TABLE (UrlReferrer NVARCHAR(300), DeviceType TINYINT, TotalClick INT, UniqueClick INT)

	SELECT	@LastDateSum = MAX(DATE) FROM dbo.ClickStatisticsSum_Country_Domain (NOLOCK) -- maybe use table sum 'ClickStatisticsSum_Country_Sport' or 'ClickStatisticsSum_Sport_Language'

	SELECT	@FromDate = CONVERT(VARCHAR(10), @FromDate, 120)
			,@ToDate  = DATEADD(MILLISECOND, -3, DATEADD(DAY, DATEDIFF(DAY, 0, @ToDate) + 1, 0)) -- the end of day "@ToDate"

	IF (@LastDateSum < @FromDate) 
	BEGIN
		INSERT INTO @Result(UrlReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, DeviceType, SUM(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId 			= @AffID
				AND DomainReferrer 	= ISNULL(@Domain, DomainReferrer)
				AND Country 		= ISNULL(@CountryCode, Country)
				AND SportCode 		= ISNULL(@SportCode, SportCode)
				AND LanguageCode 	= ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType, [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
	END
	ELSE IF (@LastDateSum > @ToDate) 
	BEGIN
		;WITH CTE_Date AS (
              SELECT @FromDate AS [Date]
              UNION ALL
              SELECT DATEADD(DAY, 1, [Date])
              FROM CTE_Date
              WHERE DATEADD(DAY, 1, [Date]) < @ToDate
        )
		INSERT INTO @Result(UrlReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, COUNT(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
				INNER JOIN CTE_Date t ON t.[Date] = c.[Date]
			WHERE AffId 			= @AffID
				AND DomainReferrer 	= ISNULL(@Domain, DomainReferrer)
				AND (CASE WHEN c.[Date] >= @BeginRegenData OR @LanguageCode IS NOT NULL  THEN Country ELSE '-' END) = ISNULL(@CountryCode, Country )
				AND SportCode 		= ISNULL(@SportCode, SportCode)
				AND LanguageCode 	= ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0), c.[Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
		OPTION(MAXRECURSION 0)
	END
	ELSE 
	BEGIN
		;WITH CTE_Date AS (
              SELECT @FromDate AS [Date]
              UNION ALL
              SELECT DATEADD(DAY, 1, [Date])
              FROM CTE_Date
              WHERE DATEADD(DAY, 1, [Date]) <= @LastDateSum
        )
		INSERT INTO @Result(UrlReferrer, DeviceType, TotalClick, UniqueClick)
		SELECT URLReferrer, DeviceType, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM
		(
			SELECT URLReferrer, ISNULL(DeviceType, 0) AS DeviceType, COUNT(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
				INNER JOIN CTE_Date t ON t.[Date] = c.[Date]
			WHERE AffId 			= @AffID
				AND DomainReferrer 	= ISNULL(@Domain, DomainReferrer)
				AND (CASE WHEN c.[Date] >= @BeginRegenData OR @LanguageCode IS NOT NULL  THEN Country ELSE '-' END) = ISNULL(@CountryCode, Country)
				AND SportCode 		= ISNULL(@SportCode, SportCode)
				AND LanguageCode 	= ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, ISNULL(DeviceType, 0), c.[Date]
			UNION ALL
			SELECT URLReferrer, DeviceType, COUNT(1) AS TotalClick, COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum AND @ToDate
				AND AffId 			= @AffID
				AND DomainReferrer 	= ISNULL(@Domain, DomainReferrer)
				AND Country 		= ISNULL(@CountryCode, Country)
				AND SportCode 		= ISNULL(@SportCode, SportCode)
				AND LanguageCode 	= ISNULL(@LanguageCode, LanguageCode)
			GROUP BY URLReferrer, DeviceType, [Date]
		) AS t
		GROUP BY URLReferrer, DeviceType
		OPTION(MAXRECURSION 0)
	END

	SELECT @NRows = COUNT(DISTINCT URLReferrer) FROM @Result WHERE DeviceType = @DeviceType
	
	IF ISNULL(@NRows, 0) = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END
		,@PageIndex = @PageIndex - 1
		,@RowStart 	= @PageSize * @PageIndex + 1
		,@RowEnd 	= @RowStart + @PageSize - 1
		
	CREATE TABLE #memberStats (URLReferrer NVARCHAR(600), DeviceType TINYINT, Signups BIGINT, FDM BIGINT)

	DECLARE @tmp TABLE (ClickID BIGINT)
	
	INSERT INTO @tmp (ClickID)
	SELECT ISNULL(ClickID, 0)
	FROM DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust WITH(NOLOCK)
	WHERE creatdate BETWEEN @FromDate AND @ToDate 
		AND AffiliateID = @AffID
	
	;WITH memberStats AS (
		-- sign-up
		SELECT
			COALESCE(c.URLReferrer, csk.URLReferrer, 'none') AS URLReferrer
			,COALESCE(c.DeviceType, csk.DeviceType, 0) 		 AS DeviceType
			,COUNT(1)									 	 AS Signups
			,0 												 AS FDM
		FROM @tmp tmp
			LEFT JOIN dbo.ClickStatistics1 c  WITH (NOLOCK) ON tmp.ClickID = c.ClickID
			LEFT JOIN ClickStatistics1_bk csk WITH (NOLOCK) ON tmp.ClickID = csk.ClickID
		WHERE 	ISNULL(c.DomainReferrer, csk.DomainReferrer) = COALESCE(@Domain, c.DomainReferrer, csk.DomainReferrer)
			AND ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) = COALESCE(@CountryCode, c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END)
			AND ISNULL(c.SportCode, csk.SportCode)  		 = COALESCE(@SportCode, c.SportCode, csk.SportCode)
			AND ISNULL(c.LanguageCode, csk.LanguageCode) 	 = COALESCE(@LanguageCode, c.LanguageCode, csk.LanguageCode)
		GROUP BY
			COALESCE(c.URLReferrer, csk.URLReferrer, 'none')
			,COALESCE(c.DeviceType, csk.DeviceType, 0)

		UNION ALL
		-- FDM
		SELECT
			ISNULL(md.URLReferrer, 'none') 	AS URLReferrer
			,ISNULL(md.DeviceType, 0) 		AS DeviceType
			,0 								AS Signups
			,COUNT(mi.IBCCustID) 			AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID AND md.AffID = @AffID
			LEFT JOIN ClickStatistics1 c 	   WITH (NOLOCK) ON c.ClickID    = md.ClickID
			LEFT JOIN ClickStatistics1_bk csk  WITH (NOLOCK) ON csk.ClickID  = md.ClickID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND (@Domain IS NULL OR ISNULL(md.DomainReferrer, 'none') = @Domain)
			AND (@CountryCode IS NULL OR COALESCE(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END, '-') = @CountryCode)
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (@LanguageCode IS NULL OR ISNULL(md.LanguageCode, 'none') = @LanguageCode)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.IBCCustID = mi.IBCCustID
					AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY ISNULL(md.URLReferrer, 'none'), ISNULL(md.DeviceType, 0)
	)
	INSERT INTO #memberStats (URLReferrer, DeviceType, Signups, FDM)
	SELECT URLReferrer, DeviceType, SUM(Signups), SUM(FDM)
	FROM memberStats
	GROUP BY URLReferrer, DeviceType

	;WITH CTE_UrlReferrer AS
	(
		SELECT
			ROW_NUMBER() OVER (ORDER BY URLReferrer) AS TheCount
			,URLReferrer
		FROM (
			SELECT DISTINCT URLReferrer
			FROM (
				SELECT TOP (@RowEnd) URLReferrer FROM @Result WHERE DeviceType = @DeviceType ORDER BY URLReferrer
				UNION ALL
				SELECT TOP (@RowEnd) URLReferrer FROM #memberStats WHERE DeviceType = @DeviceType ORDER BY URLReferrer
			) A
		) B
	)
	SELECT
		c.UrlReferrer
		,ISNULL(r.TotalClick, 0)  AS TotalClick
		,ISNULL(r.UniqueClick, 0) AS UniqueClick
		,ISNULL(m.Signups, 0) 	  AS Signups
		,ISNULL(m.FDM, 0) 	      AS FDM
	FROM CTE_UrlReferrer c
		LEFT JOIN @Result r ON c.URLReferrer = r.URLReferrer AND r.DeviceType = @DeviceType
		LEFT JOIN #memberStats m ON c.URLReferrer = m.URLReferrer AND m.DeviceType = @DeviceType
	WHERE c.TheCount BETWEEN @RowStart AND @RowEnd

	DROP TABLE #memberStats
END
GO