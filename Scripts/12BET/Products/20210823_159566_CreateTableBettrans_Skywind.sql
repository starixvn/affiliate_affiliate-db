/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210823@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate Skywind product
*/


USE Affiliate_12BET
GO

CREATE TABLE dbo.bettrans_Skywind
(
	roundId			VARCHAR(32) COLLATE SQL_Latin1_General_CP1_CS_AS
	,PlayerCode		VARCHAR(32)
	,Currency		VARCHAR(3)
	,Bet			MONEY
	,revenue		MONEY
	,ts				DATETIME
	,IBCCustId		INT
	,WinlostDate	SMALLDATETIME
	,CONSTRAINT	PK_bettrans_Skywind PRIMARY KEY NONCLUSTERED
	(
		roundId ASC
	)
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_Skywind (WinlostDate, IBCCustId) ON ReportData
GO


INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
VALUES (32, 'Skywind', '12Sky', 0, 1, 0)
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (32, 'LastQueueId', '0')
		,(32, 'LaunchDate', '2021-08-01')
		,(32, 'SourceTable', 'APIProduct_ImportQueue')
GO

INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,32,GroupProductId,NextGroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,GroupProductId,NextGroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO

INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
SELECT GroupID,'2021-08-31',DeductionID,DeductedPercentage,32,GroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,GroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO