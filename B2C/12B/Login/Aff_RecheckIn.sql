/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_RecheckIn]     
	@On_UserId INT,
	@IsKickedOut BIT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Login function - Recheckin

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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