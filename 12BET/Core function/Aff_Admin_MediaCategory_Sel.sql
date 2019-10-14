/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCategory_Sel]
	@TypeId TINYINT = 0
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Get Category

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT CategoryId, Category, ParentCategoryId
	FROM dbo.Aff_f_MediaCategory_Sel()
	WHERE (@TypeId = 0 OR TypeId = @TypeId)
	ORDER BY CategoryId
END
GO