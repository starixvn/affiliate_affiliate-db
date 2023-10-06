/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230417@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE bt WITH (ROWLOCK, UPDLOCK)-- having 1060 rows
FROM dbo.bettrans_VRLottery bt   
WHERE bt.WinlostDate > '2023-03-31 00:00:00'
GO