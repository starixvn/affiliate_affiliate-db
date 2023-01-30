/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220920@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Regen data for ClickStatistics1Sum [RedmineId : #176390]
*/

DECLARE @BeginRegenData SMALLDATETIME = CONVERT(SMALLDATETIME, '2020-08-01') --Regen data country since 01/Aug/2020

DECLARE @MonthDate DATETIME, @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

SELECT @MonthDate = @BeginRegenData 
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

WHILE 1 = 1
BEGIN
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
		,Country
	FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
	WHERE Date BETWEEN @FirstDayOfMonth AND @LastDayOfMonth
	GROUP BY
		AffId
		,DomainReferrer
		,Date
		,SportCode
		,LanguageCode
		,DeviceType
		,Country

	SELECT 
		@MonthDate = DATEADD(MONTH, 1, @MonthDate)
	   ,@FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
       ,@LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	IF @MonthDate > GETDATE()
		RETURN
END

