/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231115@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 3576 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 19 AND rpt.WinlostDate > '2023-10-31 00:00:00'
GO