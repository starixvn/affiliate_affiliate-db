/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230628@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE bt WITH (ROWLOCK, UPDLOCK)-- having 50 rows
FROM dbo.Sum_Winloss_IMEsports bt   
WHERE bt.WinlostDate > '2023-07-31 00:00:00'
GO