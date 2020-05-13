/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/

/*
	Created: 20200513@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Initialize data for PlatFormFee (DeductionId = 10)
*/

DECLARE @PlatFormFee TABLE (GroupId INT, MonthDate SMALLDATETIME, ProductId INT)
INSERT INTO @PlatFormFee (GroupId, MonthDate, ProductId)
SELECT c.GroupId, '2020-05-31' AS MonthDate, p.ProductId
FROM dbo.CommGroup c WITH (NOLOCK)
	CROSS JOIN dbo.Products p WITH (NOLOCK)

DELETE p
FROM @PlatFormFee p
	INNER JOIN dbo.DeductionSettingHistory d WITH (NOLOCK)
		ON p.GroupId = d.GroupId AND p.MonthDate = d.MonthDate AND p.ProductId = d.ProductId
WHERE d.DeductionId = 10

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage)
SELECT GroupId, MonthDate, 10 AS DeductionId, ProductId, 1 AS GroupProductId, 0.17 AS DeductedPercentage FROM @PlatFormFee