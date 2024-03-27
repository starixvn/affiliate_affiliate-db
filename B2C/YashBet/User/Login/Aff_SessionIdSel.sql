/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_SessionIdSel]
	@OnUserId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Login - Get SessionId

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON
	
	SELECT NetSessionID
	FROM dbo.On_User WITH (NOLOCK) 
	WHERE On_UserID = @OnUserId
END
GO