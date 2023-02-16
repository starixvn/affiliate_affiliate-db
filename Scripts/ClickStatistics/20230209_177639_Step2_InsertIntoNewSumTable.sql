/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230209@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Insert into 3 tables Sum [RedmineId : #177639]
*/

DECLARE @BeginInsertData SMALLDATETIME = CONVERT(SMALLDATETIME, '2015-01-01') --Insert data country since 01/Jan/2015

DECLARE @BeginRegenData SMALLDATETIME
SELECT @BeginRegenData = SValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE SName = 'AFF_OldClickStatisticsDate'--Regen data country since 01/Aug/2020

DECLARE @MonthDate DATETIME, @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

SELECT @MonthDate = @BeginInsertData 
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

CREATE TABLE #tmpClickStatistics1_bk([AffID] INT, [Date] SMALLDATETIME, [IP] VARCHAR(45), [DeviceType] TINYINT, [DomainReferrer] NVARCHAR(300), [CountryCode] NVARCHAR(256), [SportCode] NVARCHAR(50), [LanguageCode] NVARCHAR(10))

WHILE 1 = 1
BEGIN
	
	INSERT INTO #tmpClickStatistics1_bk([AffID], [Date], [IP], [DeviceType], [DomainReferrer], [CountryCode], [SportCode], [LanguageCode])
	SELECT [AffID], [Date], [IP], [DeviceType], [DomainReferrer], [Country], [SportCode], [LanguageCode]
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	
	-- table: ClickStatisticsSum_Country_Domain
	INSERT INTO [dbo].[ClickStatisticsSum_Country_Domain]
	(
		AffID
		,Date
		,TotalClick
		,UniqueClick
		,DeviceType
		,DomainReferrer
		,CountryCode
	)
	SELECT
		AffId
		,Date
		,COUNT(1) AS TotalClick
		,COUNT (DISTINCT IP) AS UniqueClick
		,DeviceType
		,DomainReferrer
		,CASE WHEN Date >= @BeginRegenData THEN CountryCode ELSE '-' END AS CountryCode
	FROM #tmpClickStatistics1_bk
	GROUP BY AffId, Date, DeviceType, DomainReferrer, CountryCode
	
	-- table: ClickStatisticsSum_Country_Sport
	INSERT INTO [dbo].[ClickStatisticsSum_Country_Sport]
	(
		AffID
		,Date
		,TotalClick
		,UniqueClick
		,DeviceType
		,CountryCode
		,SportCode
	)
	SELECT
		AffId
		,Date
		,COUNT(1) AS TotalClick
		,COUNT (DISTINCT IP) AS UniqueClick
		,DeviceType
		,CASE WHEN Date >= @BeginRegenData THEN CountryCode ELSE '-' END AS CountryCode
		,SportCode
	FROM #tmpClickStatistics1_bk
	GROUP BY AffId, Date, DeviceType, CountryCode, SportCode
	
-- table: ClickStatisticsSum_Sport_Language	
	INSERT INTO [dbo].[ClickStatisticsSum_Sport_Language]
	(
		AffID
		,Date
		,TotalClick
		,UniqueClick
		,DeviceType
		,SportCode
		,LanguageCode
	)
	SELECT
		AffId
		,Date
		,COUNT(1) AS TotalClick
		,COUNT (DISTINCT IP) AS UniqueClick
		,DeviceType
		,SportCode
		,LanguageCode
	FROM #tmpClickStatistics1_bk
	GROUP BY AffId, Date, DeviceType, SportCode, LanguageCode
	
	TRUNCATE TABLE #tmpClickStatistics1_bk

	SELECT 
		@MonthDate = DATEADD(MONTH, 1, @MonthDate)
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	IF @MonthDate > GETDATE()
		RETURN
END