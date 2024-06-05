/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240605@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: ReCalculate Commission [RedmineId : #180311]
*/

UPDATE tt
SET tt.SValue  = '2024-04-30'
FROM SystemSettings tt WITH (ROWLOCK, UPDLOCK)
WHERE SName = 'AFF_CommissionDate'
GO