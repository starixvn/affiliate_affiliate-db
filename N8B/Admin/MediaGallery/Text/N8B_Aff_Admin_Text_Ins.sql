/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Ins]
	@UserId			INT
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
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Media Gallery - Text - Insert

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

	BEGIN TRY
		INSERT INTO dbo.MediaGallery (FileName, TargetId, Message, Categories, Language, ImageType, Currencies, UpdatedDate, CreatedDate, Creator, DeviceTypes)
		VALUES ('', @TargetId, @Message, @Category, @Language, 'Text', @Currency, GETDATE(), GETDATE(), @UserId, @DeviceType)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 'Message=' + ISNULL(@Message, '')
					+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(5), @TargetId), '')
					+ ',' + 'Category=' + ISNULL(@Category, '')
					+ ',' + 'Language=' + ISNULL(@Language, '')
					+ ',' + 'Currency=' + ISNULL(@Currency, '')
					+ ',' + 'DeviceType=' + ISNULL(@DeviceType, '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO