/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroupNormal_Sel]
	@AffID INT = -1,
	@GroupTypeId INT = -1,
	@GroupID INT = -1 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Left menu - Change commission group - Dropdown Commission Group

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250526@Lewis: Exclude grouptypeid = 3 4 [RedmineID: #228530]
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
		AND GroupTypeId = 1 --revenue only
		AND EXISTS (SELECT 1 FROM dbo.TierSetting ts WITH (NOLOCK) WHERE cg.GroupId = ts.GroupId)
END	 
GO