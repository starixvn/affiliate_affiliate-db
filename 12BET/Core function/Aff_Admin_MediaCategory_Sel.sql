/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCategory_Sel]
	@TypeId TINYINT = 0
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Get Category

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		ParentCategory AS Category
		,CASE WHEN ParentCategory = Category THEN NULL ELSE Category END AS SubCategory
	FROM dbo.Aff_f_MediaCategory_Sel()
	WHERE (@TypeId = 0 OR TypeId = @TypeId)
	ORDER BY ParentCategoryId, SubCategory
END
GO