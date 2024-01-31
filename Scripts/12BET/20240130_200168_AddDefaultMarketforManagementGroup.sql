/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240130@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 Add default market for 'Management' Group [RedmineId : #200168]
*/

INSERT INTO RoleMarket(RoleId, MarketId)
VALUES (1, 'bn-BD')
	  ,(1, 'hi'   )
	  ,(1, 'ja-JP')
	  ,(1, 'km-KH')
	  ,(1, 'te-IN')
GO