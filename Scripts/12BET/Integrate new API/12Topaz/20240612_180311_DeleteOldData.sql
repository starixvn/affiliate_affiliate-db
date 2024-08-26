/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240612@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete old data [RedmineId : #180311]

*/
DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 167 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 23 AND rpt.WinlostDate > '2024-05-31 00:00:00'
GO