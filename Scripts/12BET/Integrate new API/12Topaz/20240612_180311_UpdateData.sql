/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240612@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update Data for "12 Topaz" [RedmineId : #180311]
*/
UPDATE dbo.Products WITH(ROWLOCK, UPDLOCK)
SET ProductName = '12Topaz'
WHERE ProductName = '12 Topaz'
GO