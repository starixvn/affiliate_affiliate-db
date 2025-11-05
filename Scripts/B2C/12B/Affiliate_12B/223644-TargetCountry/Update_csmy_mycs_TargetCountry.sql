/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #227338]
*/
USE Affiliate_12B;
GO

UPDATE TargetCountry SET ShortedCode ='mycs'
WHERE ShortedCode = 'csmy'