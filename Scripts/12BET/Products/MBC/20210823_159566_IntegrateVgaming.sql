/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210524@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate  Saba.club [RedmineId : #155701]
*/

DECLARE @MonthDate DATETIME

SELECT @MonthDate = '2022-08-31'

INSERT INTO Products (ProductId,ProductName,ProductPrefix,IsIBC,TransferType,Enabled,IsTest,EndOfSupportDate,ReleasedDate)
VALUES (39, 'Vgaming', 'VGA', 1, 0, 1, 0, NULL, '2022-08-01')

;WITH CTE_Products (ProductId) AS
(
	SELECT 39 --Virtual Games
),CTE AS
(
	SELECT  x.GroupID, x.DeductionID, x.DeductedPercentage, x.NextDeductedPercentage, x.GroupProductId ,x.NextGroupProductId
	FROM 
	(
		SELECT
			d.GroupID
			,d.DeductionID
			,d.DeductedPercentage
			,d.NextDeductedPercentage
			,d.GroupProductId
			,d.NextGroupProductId
			,ROW_NUMBER() OVER(PARTITION BY d.GroupId ORDER BY d.GroupProductId) as Rn
		FROM DeductionSetting d WITH(NOLOCK)
		WHERE DeductionID = 10
	) x
	WHERE x.Rn = 1
)
INSERT INTO DeductionSetting (GroupID, DeductionID, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT e.GroupID, e.DeductionID, e.DeductedPercentage, e.NextDeductedPercentage, p.ProductId, e.GroupProductId, e.NextGroupProductId
FROM CTE e, CTE_Products p


;WITH CTE_Products (ProductId) AS
(
	SELECT 39 --Vgaming
), CTE AS
(
	SELECT  x.GroupID, x.DeductionID, x.DeductedPercentage, x.NextDeductedPercentage, x.GroupProductId ,x.NextGroupProductId
	FROM 
	(
		SELECT
			d.GroupID
			,d.DeductionID
			,d.DeductedPercentage
			,d.NextDeductedPercentage
			,d.GroupProductId
			,d.NextGroupProductId
			,ROW_NUMBER() OVER(PARTITION BY d.GroupId ORDER BY d.GroupProductId) as Rn
		FROM DeductionSetting d WITH(NOLOCK)
		WHERE DeductionID = 10
	) x
	WHERE x.Rn = 1
)
INSERT INTO DeductionSettingHistory (GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId, GroupProductId)
SELECT e.GroupID, @MonthDate, e.DeductionID, e.DeductedPercentage, p.ProductId, e.GroupProductId
FROM CTE e, CTE_Products p
