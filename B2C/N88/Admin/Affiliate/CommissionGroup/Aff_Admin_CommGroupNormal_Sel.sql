/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroupNormal_Sel]
	@AffID INT = -1,
	@GroupTypeId INT = -1,
	@GroupID INT = -1 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Customer - Left menu - Change commission group - Dropdown Commission Group

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20240426@Sally: Calculate Revenue Share By Turnover [RedmineID: #204177]
*/

BEGIN
	SET NOCOUNT ON
	
	IF @AffID <> -1
		SELECT @GroupID = GroupID FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	SELECT GroupId, GroupName, cg.GroupTypeId
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE IsPrivate = 0
		AND IsDeleted = 0
		AND (cg.GroupTypeId = @GroupTypeId OR @GroupTypeId = -1)
		AND EXISTS (SELECT 1 FROM dbo.TierSetting ts WITH (NOLOCK) WHERE cg.GroupId = ts.GroupId)
END	 
GO
