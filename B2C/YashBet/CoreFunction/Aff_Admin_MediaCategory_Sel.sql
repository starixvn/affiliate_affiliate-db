/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCategory_Sel]
	@TypeId		TINYINT = 1
	,@TargetId	TINYINT = 0
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Media Gallery - Get Category

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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