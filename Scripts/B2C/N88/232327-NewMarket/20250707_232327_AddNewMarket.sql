/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250707@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Add English (Philippines) Market [RedmineId : #232327]
*/
USE Affiliate_N88
GO

INSERT INTO Market (MarketId, MarketName, MarketNativeName, ShortedCode, DisplayName)
VALUES ('en-PH', 'English (Philippines)', 'English (Philippines)', 'phien','English (Philippines)')
GO