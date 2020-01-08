USE [Affiliate_12BET]
GO

/*
	Created: 20200108@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate setting of PlatFormFee (DeductionId = 10) for LB Keno, GPI Lottery, VR Lottery, 12Topaz (ProductId: 20 21 22 23)
*/

DECLARE @MonthDate SMALLDATETIME = '2020-01-31'

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
WHERE pf.RN = 1 AND p.ProductId IN (20, 21, 22, 23)

-- History Setting
INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT pf.GroupId, @MonthDate AS MonthDate, pf.DeductionId, pf.DeductedPercentage, p.ProductId, pf.GroupProductId
FROM
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY GroupId ORDER BY ProductId) AS RN
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupProductId = 1 AND DeductionId = 10
) AS pf
	CROSS JOIN dbo.Products p WITH (NOLOCK)
WHERE pf.RN = 1 AND p.ProductId IN (20, 21, 22, 23)