/*<info serverAlias="DBAFF12B-Affiliate_12B"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20250616@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Support PHP [RedmineID: #240520]
*/
use Affiliate_12B
go

INSERT INTO TargetCountry (MarketID, MarketName, CountryCode, CountryName, OrderNo, ShortedCode)
VALUES ('en-US', 'English', 'PH', 'Philippines', 10, 'phen');
go

INSERT INTO Country (CountryCode, CountryName)
VALUES ('PH','Philippines')