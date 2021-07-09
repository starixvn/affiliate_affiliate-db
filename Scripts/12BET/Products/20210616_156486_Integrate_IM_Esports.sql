/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
USE [Affiliate_12BET]
GO

/*
	Created: 20210616@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate IM Esports [RedmineID : #156486]
*/

INSERT INTO Products (ProductId, ProductName, ProductPrefix, IsIBC, TransferType, Enabled, IsTest, EndOfSupportDate, ReleasedDate)
VALUES (31, 'IM Esports', '12IMES', 0, 0, 1, 0, NULL, NULL)

DECLARE @MonthDate SMALLDATETIME = '2021-07-31'

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (31, 'LastQueueId', '0')
		,(31, 'LaunchDate', '2021-07-01')
		,(31, 'SourceTable', 'APIProduct_ImportQueue')

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
WHERE pf.RN = 1 AND p.ProductId = 31

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
WHERE pf.RN = 1 AND p.ProductId = 31