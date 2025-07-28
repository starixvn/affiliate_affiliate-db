/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250707@Eddie
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Add new column [RedmineID: #232323]

*/

ALTER TABLE dbo.TierSetting
ADD MinFTDCount INT NULL, MaxFTDCount INT NULL, MinTotalDeposit MONEY NULL, MaxTotalDeposit MONEY NULL;
GO

ALTER TABLE dbo.TierSettingHistory
ADD MinFTDCount INT NULL, MaxFTDCount INT NULL, MinTotalDeposit MONEY NULL, MaxTotalDeposit MONEY NULL;
GO