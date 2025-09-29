/*<info serverAlias="DBAFFN88-Affiliate_N88" ></info>*/
/*
	Created: 20250730@Lewis
	DB: DBAFFN88-Affiliate_N88
	Task: Update AFFCategoryId for Marketing Accounts under MKT group [RedmineID: #234632]
	Revisions:
		- 20250730@Lewis: Update AFFCategoryId for Marketing Accounts under MKT group [RedmineID: #234632]
*/
USE Affiliate_N88;
GO
	-- Update AffCategoryId to 2 for GroupID IN (7,8)
	UPDATE ai WITH (UPDLOCK, ROWLOCK)
	SET AffCategoryId = 2
	FROM dbo.AffInfo ai
	WHERE ai.GroupId IN (7, 8);
	