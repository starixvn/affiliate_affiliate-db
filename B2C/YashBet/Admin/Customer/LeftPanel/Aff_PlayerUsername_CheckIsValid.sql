/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_PlayerUsername_CheckIsValid]
	@Player_Username	VARCHAR(30)
	,@AffId				INT = 0
	,@IsValid			BIT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Check Player_Username is valid or not

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteName VARCHAR(30)
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName')

	SET @IsValid = 0

	IF NOT EXISTS (SELECT 1 FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE username2 = @SiteName + '$' + @Player_Username)
	BEGIN
		SET @IsValid = 0
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE Player_Username = @Player_Username AND (@AffId = 0 OR AffId <> @AffId))
	BEGIN
		SET @IsValid = 0
		RETURN
	END

	SET @IsValid = 1
END
GO