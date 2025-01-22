/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaChannel_Sel]
	@AffId INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ChannelCode, ChannelName
	FROM dbo.AffMediaChannel WITH (NOLOCK)
	WHERE AffId = @AffId
END
GO