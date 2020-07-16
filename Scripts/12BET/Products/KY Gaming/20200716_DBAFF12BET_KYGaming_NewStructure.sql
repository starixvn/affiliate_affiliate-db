/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20200716@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate KY Gaming product
*/

USE Affiliate_12BET
GO

CREATE TABLE dbo.bettrans_KYGaming
(
	GameID			NVARCHAR(50)
	,Accounts		NVARCHAR(50)
	,ServerID		INT
	,KindID			INT
	,TableID		INT
	,ChairID		INT
	,UserCount		INT
	,CardValue		NVARCHAR(MAX)
	,CellScore		FLOAT
	,AllBet			FLOAT
	,Profit			FLOAT
	,Revenue		FLOAT
	,GameStartTime	DATETIME
	,GameEndTime	DATETIME
	,ChannelID		INT
	,LineCode		NVARCHAR(50)
	,IBCCustId		INT
	,WinlostDate	SMALLDATETIME
	,CONSTRAINT	PK_bettrans_KYGaming PRIMARY KEY NONCLUSTERED
	(
		GameID ASC
	)
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON bettrans_KYGaming (WinlostDate ASC) ON ReportData
GO

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
VALUES (24, 'KY Gaming', '12KY', 0, 1, 0)
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (24, 'LastQueueId', '0')
		,(24, 'LaunchDate', '2020-07-01')
		,(24, 'SourceTable', 'APIProduct_ImportQueue')
GO

INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,24,GroupProductId,NextGroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,GroupProductId,NextGroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO

INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
SELECT GroupID,'2020-07-31',DeductionID,DeductedPercentage,24,GroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,GroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO