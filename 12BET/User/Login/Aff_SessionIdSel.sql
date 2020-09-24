/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SessionIdSel]
	@OnUserId INT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Login - Get SessionId

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200925@Percy: Return column CustId (UserId) for internal login [RedmineID: #142235]
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT NetSessionID, CustId
	FROM dbo.On_User ou WITH (NOLOCK)
	WHERE On_UserID = @OnUserId
END
GO