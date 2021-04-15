/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210415@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate SA Gamming [RedmineId : #152957]
*/

DECLARE @MonthDate DATETIME

SELECT @MonthDate = '2021-04-30'

INSERT INTO Products (ProductId,ProductName,ProductPrefix,IsIBC,TransferType,Enabled,IsTest,EndOfSupportDate,ReleasedDate)
VALUES (26, 'SA Gaming', 'SAG', 1, 0, 1, 0, NULL, '2021-04-01')

;WITH CTE AS
(
	SELECT  x.GroupID, x.DeductionID, x.DeductedPercentage, x.NextDeductedPercentage, 26 AS ProductId, x.GroupProductId ,x.NextGroupProductId
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
SELECT e.GroupID, e.DeductionID, e.DeductedPercentage, e.NextDeductedPercentage, e.ProductId, e.GroupProductId, e.NextGroupProductId
FROM CTE e


;WITH CTE AS
(
	SELECT  x.GroupID, x.DeductionID, x.DeductedPercentage, x.NextDeductedPercentage, 26 AS ProductId, x.GroupProductId ,x.NextGroupProductId
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
SELECT e.GroupID, @MonthDate, e.DeductionID, e.DeductedPercentage, e.ProductId, e.GroupProductId
FROM CTE e
