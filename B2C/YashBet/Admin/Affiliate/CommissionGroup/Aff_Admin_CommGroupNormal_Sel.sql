/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroupNormal_Sel]
	@AffID INT = -1,
	@GroupID INT = -1 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Customer - Left menu - Change commission group - Dropdown Commission Group

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON
	
	IF @AffID <> -1
		SELECT @GroupID = GroupID FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	SELECT GroupId, GroupName
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE IsPrivate = 0
		AND IsDeleted = 0
		AND EXISTS (SELECT 1 FROM dbo.TierSetting ts WITH (NOLOCK) WHERE cg.GroupId = ts.GroupId)
END	 
GO