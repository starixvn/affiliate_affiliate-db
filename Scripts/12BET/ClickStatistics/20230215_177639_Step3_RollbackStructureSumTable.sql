/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230215@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Rollback structure of table 'ClickStatistics1Sum' [RedmineId : #177639]
*/
ALTER TABLE dbo.ClickStatistics1Sum
DROP CONSTRAINT [PK_Affiliate_ClickStatistics1Sum]
GO

ALTER TABLE dbo.ClickStatistics1Sum
ADD CONSTRAINT [PK_Affiliate_ClickStatistics1Sum] PRIMARY KEY ([Date], [AffID], [DomainReferrer], [DeviceType], [SportCode], [LanguageCode])
GO

ALTER TABLE dbo.ClickStatistics1Sum
DROP COLUMN [CountryCode]
GO