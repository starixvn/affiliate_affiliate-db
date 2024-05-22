/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240419@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 324 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 20 AND rpt.WinlostDate > '2024-04-30 00:00:00'
GO