/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SessionIdSel]
	@OnUserId INT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Login - Get SessionId

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT NetSessionID
	FROM dbo.On_User WITH (NOLOCK) 
	WHERE On_UserID = @OnUserId
END
GO