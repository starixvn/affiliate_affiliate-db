/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230512@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update ProductName for "Skywind" [RedmineId : #180311]
*/
UPDATE Products WITH(ROWLOCK, UPDLOCK)
SET ProductName = '12Sapphire - Skywind'
WHERE ProductName = 'Skywind'
GO