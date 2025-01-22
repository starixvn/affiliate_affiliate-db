/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250109@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Initial data Affiliate_12B DB [RedmineID: #212201]
*/

USE Affiliate_12B
GO

TRUNCATE TABLE DeductionSetting
TRUNCATE TABLE TierSetting
TRUNCATE TABLE StraightSetting

-- Deduction Setting
INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
SELECT t.GroupId, t.DeductionId, t.ProductId, t.GroupProductId,t.DeductedPercentage, t.DeductedAmount, t.IsDeductedPercent
FROM (
	SELECT 1 AS GroupId, 10 AS DeductionId, Type AS ProductId, 1 AS GroupProductId, 0.12000000 AS DeductedPercentage, 0.0000 AS DeductedAmount, 1 AS IsDeductedPercent
	FROM bodb_12B.dbo.TpGameType WITH (NOLOCK)
	WHERE Type NOT IN (41, 42)
	UNION ALL
	SELECT 1, 13, 0, 1, 0.03000000, 0.0000, 1
	UNION ALL
	SELECT 1, 14, 0, 1, 0.03000000, 0.0000, 1
	UNION ALL
	SELECT 2 AS GroupId, 10 AS DeductionId, Type AS ProductId, 1 AS GroupProductId, 0.00000000 AS DeductedPercentage, 0.0000 AS DeductedAmount, 1 AS IsDeductedPercent
	FROM bodb_12B.dbo.TpGameType WITH (NOLOCK)
	WHERE Type NOT IN (41, 42)
	UNION ALL
	SELECT 2, 13, 0, 1, 0.00000000, 0.0000, 1
	UNION ALL
	SELECT 2, 14, 0, 1, 0.00000000, 0.0000, 1
) AS t
	LEFT JOIN dbo.DeductionSetting ds WITH (NOLOCK) ON ds.GroupId = t.GroupId
												   AND ds.DeductionId =t.DeductionId
												   AND ds.ProductId = t.ProductId
WHERE ds.GroupId IS NULL
   OR ds.DeductionId IS NULL
   OR ds.ProductId IS NULL
GO


-- Tier Setting
INSERT INTO dbo.TierSetting (GroupId, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission, GroupProductId, IsActivePlayerSum)
SELECT t.GroupId, t.TierId, t.MinAmount, t.MaxAmount, t.MinAM, t.MaxAM, t.Commission, t.GroupProductId, t.IsActivePlayerSum
FROM (
	VALUES (1, 1, 0.0000, 100000000000.0000, 0, 1000000000, 0.00000000, 1, 1)
		 , (2, 1, 0.0000, 100000000000.0000, 0, 1000000000, 0.00000000, 1, 1)
) AS t(GroupId, TierId, MinAmount, MaxAmount, MinAM, MaxAM, Commission, GroupProductId, IsActivePlayerSum)
	LEFT JOIN dbo.TierSetting ts WITH (NOLOCK) ON ts.GroupId = t.GroupId
											  AND ts.GroupProductId = t.GroupProductId
											  AND ts.TierId = t.TierId
WHERE ts.GroupId IS NULL
   OR ts.GroupProductId IS NULL
   OR ts.TierId IS NULL
GO


-- Straight Setting
INSERT INTO dbo.StraightSetting (GroupId, ProductId, GroupProductId, DeductedPercentage, Commission)
SELECT t.GroupId, t.ProductId, t.GroupProductId, 0.00000000 AS DeductedPercentage, 0.00000000 AS Commission
FROM (
	VALUES (1, 0, 1) 
		 , (2, 0, 1)
) AS t(GroupId, ProductId, GroupProductId)
	LEFT JOIN dbo.StraightSetting st WITH (NOLOCK) ON st.GroupId = t.GroupId
												  AND st.ProductId = t.ProductId
WHERE st.ProductId IS NULL
   OR st.GroupId IS NULL
GO