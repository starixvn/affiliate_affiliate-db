USE [Affiliate_12BET]
GO

/*
	Created: 20181030@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate setting of PlatFormFee - AG Casino
*/

INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 9 AS ProductId, GroupProductId, NextGroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10 AND GroupId <> 143
) AS A
WHERE RN = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, '2018-10-31' AS MonthDate, DeductionId, DeductedPercentage, 9 AS ProductId, GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10 AND GroupId <> 143
) AS A
WHERE RN = 1
