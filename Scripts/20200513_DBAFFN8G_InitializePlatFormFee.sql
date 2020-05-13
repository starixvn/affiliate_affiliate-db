/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20200513@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Initialize data for PlatFormFee (DeductionId = 10)
*/

DECLARE @PlatFormFee TABLE (GroupId INT, ProductId INT)
INSERT INTO @PlatFormFee (GroupId, ProductId)
SELECT c.GroupId, p.ProductId
FROM dbo.CommGroup c WITH (NOLOCK)
	CROSS JOIN dbo.Products p WITH (NOLOCK)

DELETE p
FROM @PlatFormFee p
	INNER JOIN dbo.DeductionSetting d WITH (NOLOCK)
		ON p.GroupId = d.GroupId AND p.ProductId = d.ProductId
WHERE d.DeductionId = 10

INSERT INTO dbo.DeductionSetting (GroupId,DeductionId,DeductedPercentage,NextDeductedPercentage,ProductId,GroupProductId,NextGroupProductId)
SELECT GroupId,10 AS DeductionId,0.17 AS DeductedPercentage,0.17 AS NextDeductedPercentage,ProductId, 1 AS GroupProductId,1 AS NextGroupProductId FROM @PlatFormFee