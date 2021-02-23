/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffMediaChannel_Sel]
	@AffId INT
AS

/*
	Created: 20201215@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20201215@Percy: Initialize SP [RedmineID: #146201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ChannelCode, ChannelName
	FROM dbo.AffMediaChannel WITH (NOLOCK)
	WHERE AffId = @AffId
END
GO