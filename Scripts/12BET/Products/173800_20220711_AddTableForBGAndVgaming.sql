/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210823@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate Skywind product
*/
CREATE TABLE dbo.bettrans_BG_LiveCasino
(
	orderstatus		INT
	,orderTime		DATETIME
	,payment		MONEY
	,validBet		MONEY
	,loginId		VARCHAR(30)
	,orderid		BIGINT
	,IBCCustId		INT
	,WinlostDate	SMALLDATETIME
	,CONSTRAINT PK_bettrans_BG_LiveCasino PRIMARY KEY NONCLUSTERED 
	(
		orderid ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_BG_LiveCasino (WinlostDate, IBCCustId) ON [ReportData]
GO

CREATE TABLE dbo.bettrans_BG_Fish
(
	payout			MONEY
	,orderTime		DATETIME
	,validAmount	MONEY
	,loginId		VARCHAR(30)
	,betid			BIGINT
	,IBCCustId		INT
	,WinlostDate	SMALLDATETIME
	,CONSTRAINT PK_bettrans_BG_Fish PRIMARY KEY NONCLUSTERED 
	(
		betid ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_BG_Fish (WinlostDate, IBCCustId) ON ReportData 
GO

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
VALUES (37, 'BG (LiveCasino)', 'BGL', 0, 1, 0)
	,(38, 'BG (Fish)', 'BGF', 0, 1, 0)
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (37, 'LastQueueId', '0')
		,(37, 'LaunchDate', '2022-07-01')
		,(37, 'SourceTable', 'APIProduct_ImportQueue')
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (38, 'LastQueueId', '0')
		,(38, 'LaunchDate', '2022-07-01')
		,(38, 'SourceTable', 'APIProduct_ImportQueue')
GO

;WITH CTE AS
(
	SELECT 37 AS ProductId
	UNION ALL
	SELECT 38 AS ProductId
)
INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,e.ProductId,GroupProductId,NextGroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,GroupProductId,NextGroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
INNER JOIN CTE e ON  1 = 1
WHERE RN = 1
GO

;WITH CTE AS
(
	SELECT 37 AS ProductId
	UNION ALL
	SELECT 38 AS ProductId
)
INSERT INTO dbo.DeductionSettingHistory (GroupID,MonthDate,DeductionID,DeductedPercentage,ProductId,GroupProductId)
SELECT GroupID,'2022-07-31',DeductionID,DeductedPercentage,e.ProductId,GroupProductId
FROM (
	SELECT GroupID,DeductionID,DeductedPercentage,GroupProductId
		,ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY GroupProductId, ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE DeductionID = 10
) d
INNER JOIN CTE e ON  1 = 1
WHERE RN = 1
GO
