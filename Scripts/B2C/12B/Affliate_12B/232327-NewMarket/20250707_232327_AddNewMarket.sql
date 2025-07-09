/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250707@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Add English (Philippines) Market [RedmineId : #232327]
*/
USE Affiliate_12B
GO

INSERT INTO dbo.Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName, IsDeleted)
VALUES ('en-PH', 'English (Philippines)', 'English (Philippines)', 'phen','English (Philippines)', 0)
GO
 
INSERT INTO dbo.TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
VALUES ('en-PH', 'English (Philippines)', 'PH', 'Philippines', 10, 'phen')
GO