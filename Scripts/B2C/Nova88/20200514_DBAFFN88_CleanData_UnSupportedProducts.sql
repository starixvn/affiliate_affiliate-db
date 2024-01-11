/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200415@Percy
	DB: DBAFFN88.Affiliate_N88
	Task: Clean data for un-supported products
*/

DELETE dbo.rptMemberDaily WITH (ROWLOCK, UPDLOCK)
WHERE ProductId > 16
GO