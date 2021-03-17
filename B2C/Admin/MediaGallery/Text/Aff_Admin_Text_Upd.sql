/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Upd]
	@UserId			INT
	,@TextId		INT
	,@TargetId		TINYINT
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
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Text - Update

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Param's Explanation:
		- @TargetId:
			1: Member text
			2: Affiliate text
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData = 'TextId=' + ISNULL(CONVERT(VARCHAR(10), MediaId), '')
						+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(5), TargetId), '')
						+ ',' + 'Message=' + ISNULL(Message, '')
						+ ',' + 'Category=' + ISNULL(Categories, '')
						+ ',' + 'Language=' + ISNULL(Language, '')
						+ ',' + 'Currency=' + ISNULL(Currencies, '')
						+ ',' + 'DeviceType=' + ISNULL(DeviceTypes, '')
	FROM dbo.MediaGallery WITH (NOLOCK)
	WHERE MediaId = @TextId
		AND TargetId = @TargetId
		AND ImageType = 'Text'

	IF @OldData IS NULL
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Text does not exist.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.MediaGallery WITH (ROWLOCK)
		SET Message			= @Message
			,Categories		= @Category
			,Language		= @Language
			,Currencies		= @Currency
			,UpdatedDate	= GETDATE()
			,UpdatedBy		= @UserId
			,DeviceTypes	= @DeviceType
		WHERE MediaId	= @TextId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'TextId=' + ISNULL(CONVERT(VARCHAR(10), @TextId), '')
						+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(5), @TargetId), '')
						+ ',' + 'Message=' + ISNULL(@Message, '')
						+ ',' + 'Category=' + ISNULL(@Category, '')
						+ ',' + 'Language=' + ISNULL(@Language, '')
						+ ',' + 'Currency=' + ISNULL(@Currency, '')
						+ ',' + 'DeviceType=' + ISNULL(@DeviceType, '')
	
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