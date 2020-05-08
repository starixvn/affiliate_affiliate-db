USE Affiliate_N88
GO

/*
	Created: 20200508@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Assign group policy
*/

UPDATE dbo.Affiliate_User WITH (ROWLOCK)
SET GroupId = 1001 -- IT group
GO