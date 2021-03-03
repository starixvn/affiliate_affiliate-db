/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CommGroup_Sel]
AS

/*
	Created: 20210223@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Core function - Get Commission Group

	Revisions:
		- 20210223@Percy: Initialize SP [RedmineID: #150493]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT GroupId, GroupName
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE IsDeleted = 0
		AND EXISTS (SELECT 1 FROM dbo.TierSetting ts WITH (NOLOCK) WHERE cg.GroupId = ts.GroupId)
END
GO