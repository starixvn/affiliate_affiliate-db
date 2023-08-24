/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230824@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update ProductName for "Playtech Casino" [RedmineId : #180311]
*/
UPDATE Products WITH (ROWLOCK, UPDLOCK)
SET ProductName = '12Emerald - Playtech'
WHERE ProductName = 'Playtech Casino'
GO