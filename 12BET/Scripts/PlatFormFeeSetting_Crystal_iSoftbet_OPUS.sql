USE [Affiliate_12BET]
GO

/*
	Created: 20181030@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate setting of PlatFormFee - iSoftbet - OPUS - Crystal (GPI)
*/

DECLARE @MonthDate SMALLDATETIME = '2018-12-31'


-- Crystal (GPI)
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 12 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, @MonthDate AS MonthDate, DeductionId, DeductedPercentage, 12 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1


-- iSoftbet
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 13 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, @MonthDate AS MonthDate, DeductionId, DeductedPercentage, 13 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1


-- OPUS
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 14 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, @MonthDate AS MonthDate, DeductionId, DeductedPercentage, 14 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS A
WHERE RN = 1