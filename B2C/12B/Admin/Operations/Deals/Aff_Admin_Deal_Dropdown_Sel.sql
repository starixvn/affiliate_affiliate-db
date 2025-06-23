/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Deal_Dropdown_Sel]
	@AffID INT = 0,
	@GroupTypeId INT = 0,
	@GroupID INT = 0 OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Customer - Left menu - Change commission group - Dropdown Commission Group

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]
*/

BEGIN
	SET NOCOUNT ON
	
	IF @AffID <> 0
		SELECT @GroupID = GroupID FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	SELECT GroupId, GroupName, cg.GroupTypeId
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE IsDeleted = 0
		AND (cg.GroupTypeId = @GroupTypeId OR @GroupTypeId = 0)
END	 
GO