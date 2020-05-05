USE Affiliate_N8B
GO

/*
	Created: 20200423@Percy
	DB: DBAFFN8B.Affiliate_N8B
	Task: Clean testing member data
*/

-- 405 rows
DELETE dbo.MemberInfo WITH (ROWLOCK, UPDLOCK)
GO