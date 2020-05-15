/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20200415@Percy
	DB: DBAFFN8G.Affiliate_N8G
	Task: Clean data for un-supported products
*/

DELETE dbo.rptMemberDaily WITH (ROWLOCK, UPDLOCK)
WHERE ProductId > 16
GO