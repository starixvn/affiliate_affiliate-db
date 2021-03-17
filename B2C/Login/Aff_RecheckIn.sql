/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_RecheckIn]     
	@On_UserId INT,
	@IsKickedOut BIT = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Login function - Recheckin

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM dbo.On_User WITH (NOLOCK) WHERE On_UserId = @On_UserId AND IsKickedOut = 1)
	BEGIN
		SET @IsKickedOut = 1
		RETURN
	END

	UPDATE dbo.On_User WITH (ROWLOCK)
	SET reload_time = CURRENT_TIMESTAMP
	WHERE On_UserId = @On_UserId

	IF @@ROWCOUNT = 0
	BEGIN
		SET @IsKickedOut = 1
		RETURN
	END

	SET @IsKickedOut = 0
END
GO
