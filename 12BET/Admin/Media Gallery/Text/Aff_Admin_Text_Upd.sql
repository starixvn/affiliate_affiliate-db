/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Upd]
	@UserId			INT
	,@TextId		INT
	,@Message		NVARCHAR(MAX)
	,@Category		VARCHAR(50)
	,@Language		VARCHAR(50)
	,@Currency		VARCHAR(50)
	,@DeviceType	VARCHAR(10)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Text - Update

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200303@Percy: Support multiple sizes and categories on banner [RedmineID: #121974]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = 'TextId=' + ISNULL(CONVERT(VARCHAR(10), BannerId), '')
						+ ',' + 'Message=' + ISNULL(Message, '')
						+ ',' + 'Category=' + ISNULL(Categories, '')
						+ ',' + 'Language=' + ISNULL(Language, '')
						+ ',' + 'Currency=' + ISNULL(Currencies, '')
						+ ',' + 'DeviceType=' + ISNULL(DeviceTypes, '')
	FROM dbo.Banners WITH (NOLOCK)
	WHERE BannerId = @TextId
		AND ImageType = 'Text'

	IF @OldData IS NULL
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Text does not exist.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.Banners WITH (ROWLOCK)
		SET Message			= @Message
			,Categories		= @Category
			,Language		= @Language
			,Currencies		= @Currency
			,UpdatedDate	= GETDATE()
			,UpdatedBy		= @UserId
			,DeviceTypes	= CONVERT(VARCHAR(10), @DeviceType)
		WHERE BannerId		= @TextId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'TextId=' + ISNULL(CONVERT(VARCHAR(10), @TextId), '')
						+ ',' + 'Message=' + ISNULL(@Message, '')
						+ ',' + 'Category=' + ISNULL(@Category, '')
						+ ',' + 'Language=' + ISNULL(@Language, '')
						+ ',' + 'Currency=' + ISNULL(@Currency, '')
						+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(10), @DeviceType), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
		,@Language	= 'en-US'
END
GO