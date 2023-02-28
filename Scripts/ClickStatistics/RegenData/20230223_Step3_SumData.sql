/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/

/*
	Created: 20230223@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data [RedmineID: #177639]

*/

DECLARE @BeginRegenData DATETIME = '2020-08-01'

CREATE TABLE #tmpClickStatistics1_bk([AffID] INT, [Date] SMALLDATETIME, [IP] VARCHAR(45), [DeviceType] TINYINT, [DomainReferrer] NVARCHAR(300), [CountryCode] NVARCHAR(256), [SportCode] NVARCHAR(50), [LanguageCode] NVARCHAR(10))

BEGIN
	
	INSERT INTO #tmpClickStatistics1_bk([AffID], [Date], [IP], [DeviceType], [DomainReferrer], [CountryCode], [SportCode], [LanguageCode])
	SELECT [AffID], [Date], [IP], [DeviceType], [DomainReferrer], CASE WHEN Date >= @BeginRegenData THEN Country ELSE '-' END AS CountryCode, [SportCode], [LanguageCode]
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date IN ('2018-01-18', '2017-12-22', '2015-05-28', '2017-06-22')
	
	PRINT 'done getting data'
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
		,CountryCode
	FROM #tmpClickStatistics1_bk
	GROUP BY AffId, Date, DeviceType, DomainReferrer, CountryCode
	
	PRINT 'done: ClickStatisticsSum_Country_Domain'
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
		,CountryCode
		,SportCode
	FROM #tmpClickStatistics1_bk r
	GROUP BY AffId, Date, DeviceType, CountryCode, SportCode
	PRINT 'done: ClickStatisticsSum_Country_Sport'
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

	PRINT 'done: ClickStatisticsSum_Sport_Language'
	--ClickStatistics1Sum
	INSERT INTO dbo.ClickStatistics1Sum
		(
			AffID
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,TotalClick
			,UniqueClick
			,DeviceType
			,CountryCode
		)
		SELECT
			AffId
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,COUNT(1) AS TotalClick
			,COUNT (DISTINCT IP) AS UniqueClick
			,DeviceType
			,CountryCode
		FROM #tmpClickStatistics1_bk
		GROUP BY
			AffId
			,DomainReferrer
			,Date
			,SportCode
			,LanguageCode
			,DeviceType
			,CountryCode
			
	PRINT 'done: ClickStatistics1Sum'
	TRUNCATE TABLE #tmpClickStatistics1_bk
	
END
    
