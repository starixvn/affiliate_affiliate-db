/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230516@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE bt WITH (ROWLOCK, UPDLOCK)-- having 160 rows
FROM dbo.bettrans_N2 bt   
WHERE bt.WinlostDate >= '2023-05-01 00:00:00'
GO