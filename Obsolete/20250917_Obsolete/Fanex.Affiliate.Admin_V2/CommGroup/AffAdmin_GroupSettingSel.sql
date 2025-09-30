USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_GroupSettingSel]
	@GroupId INT	
AS

/*
	Created: 20090719@DungTong
	Task: Get Group Setting for Editing an existing Group
	DB: DBAFF.Affiliate_Athena000
	Original:

	Revisions:
*/

BEGIN
	SET NOCOUNT ON

	SELECT GroupID, ProductID, TierID, MinAmount, MaxAmount, MinQM, MaxQM, Commission
	FROM GroupSetting WITH(NOLOCK)     
	WHERE GroupID = @GroupId
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_GroupSettingSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupSettingSel] TO [vnteam]