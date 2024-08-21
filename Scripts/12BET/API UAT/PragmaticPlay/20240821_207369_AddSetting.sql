/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240821@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting for previous month and next month [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

-- Current Setting
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT pf.GroupId, pf.DeductionId, pf.DeductedPercentage, pf.NextDeductedPercentage, p.ProductId, pf.GroupProductId, pf.NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId  IN (47, 48, 49)
GO

-- History Setting for previous month
INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT pf.GroupId, '2024-07-31' AS MonthDate, pf.DeductionId, pf.DeductedPercentage, p.ProductId, pf.GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId IN (47, 48, 49)

-- History Setting for next month
INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT pf.GroupId, '2024-08-31' AS MonthDate, pf.DeductionId, pf.DeductedPercentage, p.ProductId, pf.GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId IN (47, 48, 49)
GO

