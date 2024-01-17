/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_RecheckIn]     
	@On_UserId INT,
	@IsKickedOut BIT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Login function - Recheckin

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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