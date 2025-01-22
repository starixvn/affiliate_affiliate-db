/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_CommGroup_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function - Get Commission Group

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/
BEGIN
	SET NOCOUNT ON
	
	SELECT GroupId, GroupName
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE IsDeleted = 0
		AND EXISTS (SELECT 1 FROM dbo.TierSetting ts WITH (NOLOCK) WHERE cg.GroupId = ts.GroupId)
END
GO