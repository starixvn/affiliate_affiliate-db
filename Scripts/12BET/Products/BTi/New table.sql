/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20201216@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate BTi Product
*/
USE Affiliate_12BET
GO

CREATE TABLE dbo.bettrans_BTi
(
	BetID BIGINT
	,UserName VARCHAR(50)
	,TotalStake	MONEY
	,ValidStake MONEY
	,PL MONEY
	,BetStatus VARCHAR(30)
	,BetSettledDate DATETIME
	,IBCCustId INT
	,WinlostDate SMALLDATETIME
	,CONSTRAINT PK_bettrans_BTi PRIMARY KEY NONCLUSTERED
	(
		BetID ASC
	)
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_BTi (WinlostDate) ON ReportData
GO

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
VALUES (25, 'BTi', '12BTi', 0, 1, 0)
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (25, 'LastQueueId', '0')
		,(25, 'LaunchDate', '2021-01-01')
		,(25, 'SourceTable', 'APIProduct_ImportQueue')
GO

INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,25,GroupProductId,NextGroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,GroupProductId,NextGroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO

INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
SELECT GroupID,'2020-07-31',DeductionID,DeductedPercentage,25,GroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,GroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
WHERE RN = 1
GO