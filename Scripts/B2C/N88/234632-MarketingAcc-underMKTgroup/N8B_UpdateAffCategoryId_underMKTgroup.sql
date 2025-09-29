/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/
/*
	Created: 20250730@Lewis
	DB: DBAFFN8B-Affiliate_N8B
	Task: Update AFFCategoryId [RedmineID: #234632]

*/
--17
USE Affiliate_N8B;
GO

	-- Update AffCategoryId to 2 for GroupID IN (17)
	UPDATE ai WITH (UPDLOCK, ROWLOCK)
	SET AffCategoryId = 2
	FROM dbo.AffInfo ai
	WHERE ai.GroupId IN (17);
    