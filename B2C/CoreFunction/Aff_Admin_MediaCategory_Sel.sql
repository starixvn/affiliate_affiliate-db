/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCategory_Sel]
	@TypeId		TINYINT = 1
	,@TargetId	TINYINT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Get Category

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Param's Explanation:
		- @TypeId:
			1: Banner
			2: Text
		- @TargetId:
			0: All
			1: Member
			2: Affiliate
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		TargetId
		,ParentCategory AS Category
		,CASE WHEN ParentCategory = Category THEN NULL ELSE Category END AS SubCategory
	FROM dbo.Aff_f_MediaCategory_Sel()
	WHERE TypeId = @TypeId AND (@TargetId = 0 OR TargetId = @TargetId)
	ORDER BY ParentCategoryId, SubCategory
END
GO