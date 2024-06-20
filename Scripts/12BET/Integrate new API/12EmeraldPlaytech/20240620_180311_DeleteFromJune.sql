/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240620@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data for Playtech product from June 2024 [RedmineId : #180311]

*/
DELETE dbo.APIProductMappingSettings WITH (ROWLOCK, UPDLOCK)
WHERE ProductId = 3
GO

DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 420 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 3 AND rpt.WinlostDate > '2024-05-31 00:00:00'
GO