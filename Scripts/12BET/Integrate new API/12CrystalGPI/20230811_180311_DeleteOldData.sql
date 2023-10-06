/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230811@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 6 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 12 AND rpt.WinlostDate > '2023-07-31 00:00:00'
GO