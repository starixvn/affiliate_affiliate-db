/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20250910@Eddie
	DB: DBAFFN88-Affiliate_N88
	Task: Insert data of Philippines [RedmineID: #227560]
*/
USE Affiliate_N88
GO

INSERT INTO dbo.TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
VALUES ('en-US', 'English', 'PH', 'Philippines', 7, 'phen')
GO