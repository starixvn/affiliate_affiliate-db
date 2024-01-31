/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240124@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Insert Hindi and Telugu market [RedmineId : #200168]
*/

INSERT INTO Market(MarketID, MarketName, MarketNativeName, ShortedCode, DisplayName)
VALUES ('hi', 'Hindi', N'हिन्दी', 'hi', 'Hindi')
	 , ('te-IN', 'Telugu', N'తెలుగు', 'hitg', 'Telugu')
GO
 
INSERT INTO TargetCountry(MarketID, MarketName, CountryCode, CountryName)
VALUES ('hi', 'Hindi', 'IN', 'India')
	 , ('te-IN', 'Telugu', 'IN', 'India')
GO