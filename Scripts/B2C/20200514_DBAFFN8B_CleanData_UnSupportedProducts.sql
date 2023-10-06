/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/

/*
	Created: 20200415@Percy
	DB: DBAFFN8B.Affiliate_N8B
	Task: Clean data for un-supported products
*/

DELETE dbo.rptMemberDaily WITH (ROWLOCK, UPDLOCK)
WHERE ProductId > 16
GO