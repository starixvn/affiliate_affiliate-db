/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CommGroup_Sel]
AS

/*
	Created: 20210223@Percy
	DB: DBAFFN88-Affiliate_N88
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