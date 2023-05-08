/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230505@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting for previous month and next month [RedmineId : #180311]

*/
--Delete Current and History Setting 
DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
WHERE GroupID = 164 AND ProductId IN (41, 42)

DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE GroupID = 164 AND ProductId IN (41, 42)
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
WHERE pf.RN = 1 AND p.ProductId  IN (41, 42)
GO

-- History Setting for previous month
INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT pf.GroupId, '2023-04-30' AS MonthDate, pf.DeductionId, pf.DeductedPercentage, p.ProductId, pf.GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId IN (41, 42)

-- History Setting for next month
INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT pf.GroupId, '2023-05-31' AS MonthDate, pf.DeductionId, pf.DeductedPercentage, p.ProductId, pf.GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId IN (41, 42)
GO

