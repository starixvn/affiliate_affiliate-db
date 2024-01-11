/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200723@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Support config Fixed Amount of Fees
*/

/*
USE Affiliate_N88
USE Affiliate_N8B
USE Affiliate_N8G
*/

ALTER TABLE dbo.Deductions
	ADD DeductedAmount MONEY
		,IsDeductedPercent BIT
GO

ALTER TABLE dbo.DeductionSetting
	DROP COLUMN NextGroupProductId
GO

ALTER TABLE dbo.DeductionSetting
	DROP COLUMN NextDeductedPercentage
GO

ALTER TABLE dbo.DeductionSetting
	ADD DeductedAmount MONEY
		,IsDeductedPercent BIT
GO

ALTER TABLE dbo.DeductionSettingHistory
	ADD DeductedAmount MONEY
		,IsDeductedPercent BIT
GO

-- 3/3/3 rows
UPDATE dbo.Deductions WITH (ROWLOCK)
SET IsDeductedPercent = 1
GO

-- 56/108/144 rows
UPDATE dbo.DeductionSetting WITH (ROWLOCK)
SET IsDeductedPercent = 1, DeductedAmount = 0
GO

-- 56/454/578 rows
UPDATE dbo.DeductionSettingHistory WITH (ROWLOCK)
SET IsDeductedPercent = 1, DeductedAmount = 0
GO