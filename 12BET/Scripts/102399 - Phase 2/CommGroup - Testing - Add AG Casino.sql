USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Initialize comm group setting - testing group
*/

DECLARE @GroupId INT
SELECT  @GroupId = GroupId FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = 'CG28023-Testing'

INSERT INTO dbo.DeductionSetting (GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
SELECT GroupId, DeductionId, DeductedPercentage, NextDeductedPercentage, 9 AS ProductId, GroupProductId, NextGroupProductId
FROM dbo.DeductionSetting WITH (NOLOCK)
WHERE GroupId = @GroupId AND DeductionId = 10 AND ProductId = 1

INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, DeductedPercentage, ProductId, GroupProductId)
SELECT GroupId, MonthDate, DeductionId, DeductedPercentage, 9 AS ProductId, GroupProductId
FROM dbo.DeductionSettingHistory WITH (NOLOCK)
WHERE GroupId = @GroupId AND DeductionId = 10 AND ProductId = 1
	AND MonthDate = '2018-10-31'