/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Ins]
	@UserId			INT
	,@FileName		VARCHAR(100)
	,@Category		VARCHAR(50)
	,@Language		VARCHAR(50)
	,@Currency		VARCHAR(50)
	,@ImageType		VARCHAR(50)
	,@Size			VARCHAR(50)
	,@AffType		TINYINT
	,@DeviceType	TINYINT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Banner - Insert

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
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

	-- Check input banner
	IF @ImageType = 'Text'
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Invalid Image Type.'
		RETURN
	END

	-- Check file exists
	IF EXISTS (SELECT 1 FROM dbo.Banners WITH (NOLOCK) WHERE FileName = @FileName)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. FileName has already been exist.'
		RETURN
	END

	BEGIN TRY
		INSERT INTO dbo.Banners (FileName, Category, Language, ImageType, Size, Currency, LastUpdate, CreatedDate, Creator, AffType, DeviceType)
		VALUES (@FileName, @Category, @Language, @ImageType, @Size, @Currency, GETDATE(), GETDATE(), @UserId, @AffType, @DeviceType)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Insert unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 'FileName=' + ISNULL(@FileName, '')
					+ ',' + 'Category=' + ISNULL(@Category, '')
					+ ',' + 'Language=' + ISNULL(@Language, '')
					+ ',' + 'Currency=' + ISNULL(@Currency, '')
					+ ',' + 'ImageType=' + ISNULL(@ImageType, '')
					+ ',' + 'Size=' + ISNULL(@Size, '')
					+ ',' + 'AffType=' + ISNULL(CONVERT(VARCHAR(5), @AffType), '')
					+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(5), @DeviceType), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO