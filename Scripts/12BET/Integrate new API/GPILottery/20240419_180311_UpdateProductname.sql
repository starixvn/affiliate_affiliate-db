/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240419@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update ProductName for "GPI Lottery" [RedmineId : #180311]
*/
UPDATE Products WITH (ROWLOCK, UPDLOCK)
SET ProductName = 'GPI Lottery & Arcade'
WHERE ProductName = 'GPI Lottery'
GO