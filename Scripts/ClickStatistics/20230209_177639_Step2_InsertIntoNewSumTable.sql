/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230209@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Insert into 3 tables CSSumByCountryCode, CSSumByCountryCodeandSportCode and CSSumBySportCodeandLanguageCode [RedmineId : #177639]
*/

DECLARE @BeginRegenData SMALLDATETIME = CONVERT(SMALLDATETIME, '2020-08-01') --Regen data country since 01/Aug/2020

DECLARE @MonthDate DATETIME, @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

SELECT @MonthDate = @BeginRegenData 
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

WHILE 1 = 1
BEGIN
	-- table: CSSumByCountryCode
	INSERT INTO [dbo].[CSSumByCountryCode]
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
		,Country
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	GROUP BY
		AffId
		,Date
		,DeviceType
		,DomainReferrer
		,Country
	
	-- table: CSSumByCountryCodeandSportCode
	INSERT INTO [dbo].[CSSumByCountryCodeandSportCode]
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
		,Country
		,SportCode
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	GROUP BY
		AffId
		,Date
		,DeviceType
		,Country
		,SportCode
	
-- table: CSSumBySportCodeandLanguageCode	
	INSERT INTO [dbo].[CSSumBySportCodeandLanguageCode]
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
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	GROUP BY
		AffId
		,Date
		,DeviceType
		,SportCode
		,LanguageCode

	SELECT 
		@MonthDate = DATEADD(MONTH, 1, @MonthDate)
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	IF @MonthDate > GETDATE()
		RETURN
END