/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230428@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete data of '12Sapphire - Skywind' on UAT [RedmineId : #180311]

*/
DELETE bt WITH (ROWLOCK, UPDLOCK)-- having 438177 rows
FROM dbo.bettrans_APIProductsTest bt   
WHERE bt.TpType = 17
GO