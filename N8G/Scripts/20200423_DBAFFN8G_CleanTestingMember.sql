USE Affiliate_N8G
GO

/*
	Created: 20200423@Percy
	DB: DBAFFN8G.Affiliate_N8G
	Task: Clean testing member data
*/

-- 41 rows
DELETE dbo.MemberInfo WITH (ROWLOCK, UPDLOCK)
GO