/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230808@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE bt WITH (ROWLOCK, UPDLOCK)-- having 899 rows
FROM dbo.bettrans_KYGaming bt   
WHERE bt.WinlostDate > '2023-07-31 00:00:00'
GO