/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220511@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

UPDATE Products WITH(ROWLOCK)
	SET ProductName = 'Saba Casino'
WHERE ProductName = 'RNG Casino'
GO