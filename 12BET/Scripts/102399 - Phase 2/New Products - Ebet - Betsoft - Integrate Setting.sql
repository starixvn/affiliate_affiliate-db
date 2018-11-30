USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products
		- EBet
		- Betsoft
*/

-- Products
INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest)
SELECT 10, '12Opal - EBet', '12EB', 0, 1, 0 UNION ALL
SELECT 11, '12Amber - Betsoft', '12BS', 0, 1, 0
GO

-- API Settings
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)

SELECT 10, 'LastQueueId', '0' UNION ALL
SELECT 10, 'LaunchDate', '2018-12-01' UNION ALL
SELECT 10, 'SourceTable', 'APIProduct_ImportQueue' UNION ALL

SELECT 11, 'LastQueueId', '0' UNION ALL
SELECT 11, 'LaunchDate', '2018-12-01' UNION ALL
SELECT 11, 'SourceTable', 'APIProduct_ImportQueue'

-- Setting of platformfee
	-- EBet
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 10 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, '2018-11-30' AS MonthDate, DeductionId, DeductedPercentage, 10 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

	-- Betsoft
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 11 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, '2018-11-30' AS MonthDate, DeductionId, DeductedPercentage, 11 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1