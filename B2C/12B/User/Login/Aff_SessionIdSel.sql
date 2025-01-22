/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_SessionIdSel]
	@OnUserId INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Login - Get SessionId

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON
	
	SELECT NetSessionID
	FROM dbo.On_User WITH (NOLOCK) 
	WHERE On_UserID = @OnUserId
END
GO