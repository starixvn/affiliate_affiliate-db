USE [Affiliate_12BET]
GO

/*
	Created: 20180830@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add GroupProductId by Fees [RedmineID: #87923]
*/

ALTER TABLE dbo.DeductionSetting
	ADD GroupProductId TINYINT NULL,
		NextGroupProductId TINYINT NULL
GO

ALTER TABLE dbo.DeductionSettingHistory
	ADD GroupProductId TINYINT NULL
GO

-- 16 rows
UPDATE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
SET GroupProductId = 1, NextGroupProductId = 1
WHERE DeductionID IN (10, 11, 12)
GO

-- 16 rows
UPDATE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
SET GroupProductId = 1
WHERE DeductionID IN (10, 11, 12) AND MonthDate = '2018-08-31'

-- 16 rows
UPDATE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
SET GroupProductId = 1
WHERE DeductionID IN (10, 11, 12) AND MonthDate = '2018-09-30'
GO