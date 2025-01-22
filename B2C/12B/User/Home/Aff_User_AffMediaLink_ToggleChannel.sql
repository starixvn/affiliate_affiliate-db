/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaLink_ToggleChannel]
	@AffId			INT
	,@ChannelCode	VARCHAR(50)
	,@LanguageCode	VARCHAR(10)
	,@AffMediaLink	VARCHAR(500)
	,@IsOn			BIT = 0
	,@Language		VARCHAR(10) = 'en-US'
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(2000) = '' OUTPUT
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

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Affiliate!'
		RETURN
	END

	SELECT @OldData = 'ChannelCode=' + @ChannelCode + ',LanguageCode=' + @LanguageCode + ',AffMediaLink=' + @AffMediaLink + ',IsOn=' + CONVERT(VARCHAR(1), IsShow)
	FROM dbo.AffMediaLink WITH (NOLOCK)
	WHERE AffId = @AffId AND ChannelCode = @ChannelCode AND LanguageCode = @LanguageCode AND AffMediaLink = @AffMediaLink

	SELECT @NewData = 'ChannelCode=' + @ChannelCode + ',LanguageCode=' + @LanguageCode + ',AffMediaLink=' + @AffMediaLink + ',IsOn=' + CONVERT(VARCHAR(1), @IsOn)

	IF ISNULL(@OldData, '') = ISNULL(@NewData, '')
		RETURN

	BEGIN TRY
		UPDATE dbo.AffMediaLink WITH (ROWLOCK)
		SET IsShow = @IsOn
		WHERE AffId = @AffId AND ChannelCode = @ChannelCode AND LanguageCode = @LanguageCode AND AffMediaLink = @AffMediaLink

		IF @@ROWCOUNT = 0 AND @IsOn = 1
			INSERT INTO dbo.AffMediaLink (AffId, ChannelCode, LanguageCode, AffMediaLink, IsShow)
			VALUES (@AffId, @ChannelCode, @LanguageCode, @AffMediaLink, @IsOn)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId
		,@AffId		= @AffId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= @Language
END
GO