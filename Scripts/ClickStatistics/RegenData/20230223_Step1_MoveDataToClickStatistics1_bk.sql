/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/

/*
	Created: 20230223@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data [RedmineID: #177639]

*/
CREATE TABLE #Clicks (ClickId INT PRIMARY KEY)

CREATE TABLE #ClickDetails (ClickId INT PRIMARY KEY)

DECLARE @RowCount INT = 0

INSERT INTO #Clicks (ClickId)
SELECT ClickID
FROM dbo.ClickStatistics1 WITH(NOLOCK)
WHERE Date < '2023-02-01'

WHILE 1 = 1 
BEGIN
	
	TRUNCATE TABLE #ClickDetails

	DELETE TOP(1000) c 
		OUTPUT deleted.ClickId
		INTO #ClickDetails (ClickId)
	FROM #Clicks c
	
	IF @@ROWCOUNT = 0
		BREAK

	INSERT INTO dbo.ClickStatistics1_bk
	(
		ClickId,
		AffId,
		UpdatedTime,
		IP,
		Date,
		Browser,
		URLReferrer,
		DomainReferrer,
		OS,
		Device,
		BrowserVersion,
		BrowserResolution,
		BrowserLanguage,
		UserAgent,
		Country,
		LanguageCode,
		SportCode,
		RedirectURL,
		Status,
		DeviceType
	)
	SELECT	
		ClickId,
		AffId,
		UpdatedTime,
		IP,
		Date,
		Browser,
		URLReferrer,
		DomainReferrer,
		OS,
		Device,
		BrowserVersion,
		BrowserResolution,
		BrowserLanguage,
		UserAgent,
		Country,
		LanguageCode,
		SportCode,
		RedirectURL,
		Status,
		DeviceType
	FROM ClickStatistics1 c WITH(NOLOCK)
	WHERE EXISTS (SELECT 1 FROM #ClickDetails d WHERE d.ClickId = c.ClickID) 
		AND NOT EXISTS (SELECT 1 FROM dbo.ClickStatistics1_bk b WITH(NOLOCK) WHERE b.ClickID = c.ClickID)

	SELECT @RowCount += @@ROWCOUNT

	PRINT ('Inserted ' + CONVERT(VARCHAR(100), @RowCount) + ' Rows')
END

DROP TABLE #ClickDetails
DROP TABLE #Clicks

--Update Country Code 2 to Country Code 3

