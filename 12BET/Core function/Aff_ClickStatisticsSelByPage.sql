/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff,wsv_affv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage]
	@AffId			INT
	,@FromDate		DATETIME
	,@ToDate		DATETIME
	,@ReportBy		VARCHAR(10)   = 'Country'
	,@CountryCodes 	NVARCHAR(MAX) = NULL
	,@SportCode		VARCHAR(50)   = NULL
	,@LanguageCodes	VARCHAR(MAX)  = NULL
	,@DeviceType	TINYINT 	  = 0
	,@TotalSignUps	INT 		  = 0 OUTPUT
	,@TotalFDMs		INT 		  = 0 OUTPUT
AS

/*  
	Created: 20111005@Johnny
	DB: DBAFF12BET.Affiliate_12BET
	Task: Report click statistics by Landing page and language of landing page
	
	Revisions:  
		- 20140708@Bobby : Apply Device type info
		- 20140805@Bobby : Support sum TotalSignUps & TotalFDMs
		- 20141103@Bobby : Change FromDate & ToDate to DATETIME
		- 20170214@Percy: Fix FDM/Signup issue [RedmineID: #70507]
		- 20170515@Percy: New Signup Statistic [RedmineID: #76507]
		- 20200731@Percy: Check permission market (language) by user login [RedmineID: #121975]
		- 20220926@Eddie: Add Country info [RedmineID: #176390]
		- 20230214@Eddie: Not using 'ClickStatistics1Sum' sum table [RedmineID: #177639]
		- 20240321@Eddie: Change Link Server and metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #202712]
	
	Param's Explanation:
		- @ReportBy: 'Country' or 'Language'
		- @CountryCodes: N'-,AL,AR,...' OR N''
*/

BEGIN
	SET NOCOUNT ON

	IF (@FromDate > @ToDate) RETURN

	CREATE TABLE #tmpResult (CountryCode VARCHAR(2), SportCode VARCHAR(50), LanguageCode VARCHAR(10), DeviceType TINYINT, TotalClick INT, UniqueClick INT, Signups INT, FDM INT)

	DECLARE @Result TABLE (CountryCode VARCHAR(2), SportCode VARCHAR(50), LanguageCode VARCHAR(10), DeviceType TINYINT, TotalClick INT, UniqueClick INT)
	
	DECLARE @BeginRegenData SMALLDATETIME, @LastDateSum DATETIME

	SELECT @BeginRegenData = SValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_OldClickStatisticsDate'

	SELECT @LastDateSum = MAX(DATE) FROM dbo.ClickStatisticsSum_Country_Sport WITH(NOLOCK) -- maybe use table sum 'ClickStatisticsSum_Country_Domain' or 'ClickStatisticsSum_Sport_Language'

	SELECT @FromDate = CONVERT(VARCHAR(10), @FromDate, 120)
		   , @ToDate  = DATEADD(MILLISECOND, -3, DATEADD(DAY, DATEDIFF(DAY, 0, @ToDate) + 1, 0)) -- the end of day "@ToDate"
		   , @LastDateSum = DATEADD(SECOND, -1, DATEADD(MONTH, 1, FORMAT(@LastDateSum, 'yyyy-MM-01'))) -- the end of month "@LastDateSum"

	IF (@LastDateSum < @FromDate) 
	BEGIN
		INSERT INTO @Result(CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
		SELECT r.CountryCode, r.SportCode, r.LanguageCode, r.DeviceType, r.TotalClick, r.UniqueClick
		FROM
		(
			SELECT 
				ISNULL(CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END, '-') AS CountryCode
				,SportCode
				,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END AS LanguageCode
				,DeviceType
				,SUM(1) AS TotalClick
				,COUNT(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate AND @ToDate
				AND AffId = @AffID
				AND SportCode = ISNULL(@SportCode, SportCode)
				AND (( ',' + @CountryCodes + ',' LIKE '%,' + Country + ',%') OR (',' + @LanguageCodes + ',' LIKE '%,' + LanguageCode + ',%'))
			GROUP BY SportCode
				,CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END
				,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END
				,DeviceType
				,[Date]
		) AS r
	END
	ELSE IF (@LastDateSum > @ToDate) 
	BEGIN
		IF @ReportBy = 'Country'
		BEGIN 
			INSERT INTO @Result(CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
			SELECT r.CountryCode, r.SportCode, r.LanguageCode, r.DeviceType, r.TotalClick, r.UniqueClick
			FROM
			(
				SELECT
					SportCode
					,CountryCode
					,'none' AS LanguageCode
					,DeviceType
					,SUM(TotalClick)  AS TotalClick
					,SUM(UniqueClick) AS UniqueClick
				FROM ClickStatisticsSum_Country_Sport WITH (NOLOCK)
				WHERE [Date] BETWEEN @FromDate AND @ToDate
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND ( ',' + @CountryCodes + ',' LIKE '%,' + CountryCode + ',%')
				GROUP BY CountryCode, SportCode, DeviceType
			) AS r
		END
		ELSE
		BEGIN
			INSERT INTO @Result(CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
			SELECT r.CountryCode, r.SportCode, r.LanguageCode, r.DeviceType, r.TotalClick, r.UniqueClick
			FROM
			(
				SELECT 
					SportCode
					,'-' AS CountryCode
					,LanguageCode
					,DeviceType
					,SUM(TotalClick)  AS TotalClick
					,SUM(UniqueClick) AS UniqueClick
				FROM ClickStatisticsSum_Sport_Language WITH (NOLOCK)
				WHERE [Date] BETWEEN @FromDate AND @ToDate
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND (',' + @LanguageCodes + ',' LIKE '%,' + LanguageCode + ',%')
				GROUP BY LanguageCode, SportCode, DeviceType
			) AS r
		END
	END
	ELSE 
	BEGIN
		IF @ReportBy = 'Country'
		BEGIN
			INSERT INTO @Result(CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
			SELECT r.CountryCode, r.SportCode, r.LanguageCode, r.DeviceType, r.TotalClick, r.UniqueClick
			FROM
			(
				SELECT
					SportCode
					,CountryCode
					,'none' AS LanguageCode
					,DeviceType
					,SUM(TotalClick)  AS TotalClick
					,SUM(UniqueClick) AS UniqueClick
				FROM ClickStatisticsSum_Country_Sport WITH (NOLOCK)
				WHERE [Date] BETWEEN @FromDate AND @LastDateSum
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND ( ',' + @CountryCodes + ',' LIKE '%,' + CountryCode + ',%')
				GROUP BY CountryCode, SportCode, DeviceType

				UNION ALL
				
				SELECT 
					SportCode
					,ISNULL(CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END, '-') AS CountryCode
					,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END AS LanguageCode
					,DeviceType
					,COUNT(1) AS TotalClick
					,COUNT(DISTINCT IP) AS UniqueClick
				FROM ClickStatistics1 c WITH (NOLOCK)
				WHERE [Date] BETWEEN @LastDateSum AND @ToDate
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND (( ',' + @CountryCodes + ',' LIKE '%,' + Country + ',%') OR (',' + @LanguageCodes + ',' LIKE '%,' + LanguageCode + ',%'))
				GROUP BY SportCode
					,CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END
					,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END
					,DeviceType
					,[Date]
			) AS r
		END
		ELSE
		BEGIN
			INSERT INTO @Result(CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick)
			SELECT r.CountryCode, r.SportCode, r.LanguageCode, r.DeviceType, r.TotalClick, r.UniqueClick
			FROM
			(
				SELECT 
					SportCode
					,'-' AS CountryCode
					,LanguageCode
					,DeviceType
					,SUM(TotalClick)  AS TotalClick
					,SUM(UniqueClick) AS UniqueClick
				FROM ClickStatisticsSum_Sport_Language WITH (NOLOCK)
				WHERE [Date] BETWEEN @FromDate AND @LastDateSum
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND (',' + @LanguageCodes + ',' LIKE '%,' + LanguageCode + ',%')
				GROUP BY LanguageCode, SportCode, DeviceType
				
				UNION ALL
				
				SELECT 
					SportCode
					,ISNULL(CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END, '-') AS CountryCode
					,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END AS LanguageCode
					,DeviceType
					,COUNT(1) AS TotalClick
					,COUNT(DISTINCT IP) AS UniqueClick
				FROM ClickStatistics1 c WITH (NOLOCK)
				WHERE [Date] BETWEEN @LastDateSum AND @ToDate
					AND AffId = @AffID
					AND SportCode = ISNULL(@SportCode, SportCode)
					AND (( ',' + @CountryCodes + ',' LIKE '%,' + Country + ',%') OR (',' + @LanguageCodes + ',' LIKE '%,' + LanguageCode + ',%'))
				GROUP BY SportCode
					,CASE WHEN @ReportBy = 'Country' THEN ISNULL(Country, '-') END
					,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(LanguageCode, 'none') END
					,DeviceType
					,[Date]
			) AS r
		END
	END

	INSERT INTO #tmpResult (CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT tr.CountryCode, tr.SportCode, tr.LanguageCode, tr.DeviceType, tr.TotalClick, tr.UniqueClick, tr.Signups, tr.FDM
	FROM
	(
		SELECT 
			ISNULL(CASE WHEN @ReportBy = 'Country' THEN CountryCode END, '-') AS CountryCode
			,ISNULL(SportCode, 'none') 	 AS SportCode
			,CASE WHEN @ReportBy = 'Country'  THEN 'none' ELSE LanguageCode END AS LanguageCode
			,ISNULL(DeviceType, 0) 		 AS DeviceType
			,SUM(ISNULL(TotalClick, 0))  AS TotalClick
			,SUM(ISNULL(UniqueClick, 0)) AS UniqueClick
			,0 							 AS Signups
			,0 							 AS FDM
		FROM @Result
		GROUP BY CASE WHEN @ReportBy = 'Country' THEN CountryCode END
			,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE LanguageCode END
			,ISNULL(SportCode, 'none')
			,ISNULL(DeviceType, 0)
	) AS tr

	DECLARE @tmp TABLE (ClickID BIGINT)
	
	INSERT INTO #tmpResult (CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT tr.CountryCode, tr.SportCode, tr.LanguageCode, tr.DeviceType, tr.TotalClick, tr.UniqueClick, tr.Signups, tr.FDM
	FROM
	(
		SELECT
			ISNULL(CASE WHEN @ReportBy = 'Country' THEN ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) END, '-') AS CountryCode
			,ISNULL(md.SportCode, 'none') AS SportCode
			,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(md.LanguageCode, 'none') END AS LanguageCode
			,ISNULL(md.DeviceType, 0) 	  AS DeviceType
			,0 						  	  AS TotalClick
			,0 						  	  AS UniqueClick
			,0 						  	  AS Signups
			,COUNT(1) 				  	  AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			LEFT JOIN dbo.MemberClickDetail md WITH (NOLOCK) ON md.IBCCustID = mi.IBCCustID AND md.AffID = @AffID
			LEFT JOIN ClickStatistics1 c WITH (NOLOCK) ON c.ClickID = md.ClickID
			LEFT JOIN ClickStatistics1_bk csk WITH (NOLOCK) ON csk.ClickID = md.ClickID
		WHERE mi.CreatedDate BETWEEN @FromDate AND @ToDate
			AND mi.AffId = @AffID
			AND (@SportCode IS NULL OR ISNULL(md.SportCode, 'none') = @SportCode)
			AND (( ',' + @CountryCodes + ',' LIKE '%,' + COALESCE(c.Country, csk.Country, '-') + ',%') OR (',' + @LanguageCodes + ',' LIKE '%,' + md.LanguageCode + ',%'))
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mr.IBCCustID = mi.IBCCustID AND mr.RemovedDate BETWEEN @FromDate AND @ToDate
			)
		GROUP BY 
			CASE WHEN @ReportBy = 'Country' THEN ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) END
			,ISNULL(md.SportCode, 'none')
			,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE ISNULL(md.LanguageCode, 'none') END
			,ISNULL(md.DeviceType, 0)
	) AS tr

	INSERT INTO @tmp (ClickID)
	SELECT ISNULL(ClickID, 0)
	FROM DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust WITH(NOLOCK)
	WHERE creatdate BETWEEN @FromDate AND @ToDate AND AffiliateID = @AffID

	INSERT INTO #tmpResult (CountryCode, SportCode, LanguageCode, DeviceType, TotalClick, UniqueClick, Signups, FDM)
	SELECT tr.CountryCode, tr.SportCode, tr.LanguageCode, tr.DeviceType, tr.TotalClick, tr.UniqueClick, tr.Signups, tr.FDM
	FROM
	(
		SELECT
			ISNULL(CASE WHEN @ReportBy = 'Country' THEN ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) END, '-') AS CountryCode
			,COALESCE(c.SportCode, csk.SportCode, 'none') AS SportCode
			,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE COALESCE(c.LanguageCode, csk.LanguageCode, 'none') END AS LanguageCode
			,COALESCE(c.DeviceType, csk.DeviceType, 0) 	  AS DeviceType
			,0 										   	  AS TotalClick
			,0 										   	  AS UniqueClick
			,COUNT(1) 								   	  AS Signups
			,0 										   	  AS FDM
		FROM @tmp tmp
			LEFT JOIN dbo.ClickStatistics1 c 	  WITH (NOLOCK) ON tmp.ClickID = c.ClickID
			LEFT JOIN dbo.ClickStatistics1_bk csk WITH (NOLOCK) ON tmp.ClickID = csk.ClickID
		WHERE (@SportCode IS NULL OR COALESCE(c.SportCode, csk.SportCode, 'none') = @SportCode)
			AND ',' + @LanguageCodes + ',' LIKE '%,' + COALESCE(c.LanguageCode, csk.LanguageCode, 'none') + ',%'
		GROUP BY
			CASE WHEN @ReportBy = 'Country' THEN ISNULL(c.Country, CASE WHEN csk.Date >= @BeginRegenData THEN ISNULL(csk.Country, '-') ELSE '-' END) END
			,COALESCE(c.SportCode, csk.SportCode, 'none')
			,CASE WHEN @ReportBy = 'Country' THEN 'none' ELSE COALESCE(c.LanguageCode, csk.LanguageCode, 'none') END
			,COALESCE(c.DeviceType, csk.DeviceType, 0)
	) AS tr
	
	IF @ReportBy = 'Country'
	BEGIN
		SELECT
			tr.CountryCode 		 AS CountryCode
			,CASE WHEN tr.CountryCode <> '-' THEN c.CountryName ELSE 'Unknown' END AS Country
			,tr.SportCode 		 AS [Page]
			,SUM(tr.TotalClick)  AS TotalClick
			,SUM(tr.UniqueClick) AS UniqueClick
			,SUM(tr.Signups) 	 AS Signups
			,SUM(tr.FDM) 		 AS FDM
			,CASE WHEN tr.CountryCode <> '-' THEN 0 ELSE 1 END AS ordered
		FROM #tmpResult tr
			LEFT JOIN Country c WITH (NOLOCK) ON c.CountryCode = tr.CountryCode
		WHERE tr.DeviceType = @DeviceType
		GROUP BY tr.CountryCode
				,CASE WHEN tr.CountryCode <> '-' THEN c.CountryName ELSE 'Unknown' END
				,tr.SportCode
		ORDER BY ordered, Country
	END
	ELSE
	BEGIN
		SELECT
			tr.SportCode 					AS [Page]
			,tr.LanguageCode 				AS LanguageCode
			,ISNULL(m.MarketName, 'none') 	AS [Language]
			,SUM(tr.TotalClick) 			AS TotalClick
			,SUM(tr.UniqueClick) 			AS UniqueClick
			,SUM(tr.Signups) 				AS Signups
			,SUM(tr.FDM) 					AS FDM
		FROM #tmpResult tr
			LEFT JOIN dbo.Market m WITH (NOLOCK) on m.ShortedCode = tr.LanguageCode
		WHERE tr.DeviceType = @DeviceType
		GROUP BY tr.SportCode, tr.LanguageCode, m.MarketName
	END

	SELECT @TotalSignUps = SUM(Signups), @TotalFDMs = SUM(FDM)
	FROM #tmpResult 
	WHERE DeviceType = @DeviceType

	DROP TABLE #tmpResult
END
GO