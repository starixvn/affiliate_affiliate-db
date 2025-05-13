/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250512@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #227030]
*/

--Market
UPDATE m SET m.MarketName ='Bengali', m.MarketNativeName ='Bengali', m.DisplayName ='Bengali'
FROM Market m WITH (ROWLOCK,UPDLOCK)
WHERE MarketId = 'bn-BD'
GO

--TargetCountry
UPDATE tc SET tc.MarketName ='Bengali'
FROM TargetCountry tc WITH (ROWLOCK,UPDLOCK)
WHERE MarketId = 'bn-BD'
GO
