USE [Affiliate_12BET]
GO

/*
	Created: 20180830@Percy
*/

ALTER TABLE dbo.DeductionSetting
	ADD GroupProductId TINYINT NULL,
		NextGroupProductId TINYINT NULL
GO

ALTER TABLE dbo.DeductionSettingHistory
	ADD GroupProductId TINYINT NULL
GO

UPDATE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
SET GroupProductId = 1, NextGroupProductId = 1
WHERE DeductionID IN (10, 11, 12)
GO

UPDATE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
SET GroupProductId = 1
WHERE DeductionID IN (10, 11, 12) AND MonthDate = '2018-08-31'
GO