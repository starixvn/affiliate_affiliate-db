/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #227338]
*/
USE Affiliate_12B;
GO

INSERT INTO TargetCountry (
MarketID
,MarketName
,CountryCode
,CountryName
,OrderNo
,ShortedCode)
SELECT 'zh-CN',	'Chinese Simplified',	'MY',	'Malaysia'	,NULL,	'csmy'