/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250730@Lewis
	DB: DBAFFN8G-Affiliate_N8G
	Task: Update AFFCategoryId [RedmineID: #234632]

*/
--11
USE Affiliate_N8G;
GO

	-- Update AffCategoryId to 2 for GroupID IN (11)
	UPDATE ai WITH (UPDLOCK, ROWLOCK)
	SET AffCategoryId = 2
	FROM dbo.AffInfo ai
	WHERE ai.GroupId IN (11);