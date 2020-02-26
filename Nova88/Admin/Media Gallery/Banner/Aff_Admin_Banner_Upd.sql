/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Upd]
	@UserId			INT
	,@BannerId		INT
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
	Task: Admin - Media Gallery - Banner - Update

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

	-- Check banner exists
	DECLARE @OldSize VARCHAR(50), @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldSize = Size
			,@OldData = 'BannerId=' + ISNULL(CONVERT(VARCHAR(10), BannerId), '')
						+ ',' + 'FileName=' + ISNULL(FileName, '')
						+ ',' + 'Category=' + ISNULL(Category, '')
						+ ',' + 'Language=' + ISNULL(Language, '')
						+ ',' + 'Currency=' + ISNULL(Currency, '')
						+ ',' + 'ImageType=' + ISNULL(ImageType, '')
						+ ',' + 'Size=' + ISNULL(Size, '')
						+ ',' + 'AffType=' + ISNULL(CONVERT(VARCHAR(5), AffType), '')
						+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(5), DeviceType), '')
	FROM dbo.Banners WITH (NOLOCK)
	WHERE BannerId = @BannerId
		AND ImageType <> 'Text'

	IF @OldSize IS NULL
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Error occurs. Banner does not exist.'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.Banners WITH (ROWLOCK)
		SET FileName	= @FileName
			,Category	= @Category
			,Language	= @Language
			,ImageType	= @ImageType
			,Size		= @Size
			,Currency	= @Currency
			,LastUpdate = GETDATE()
			,UpdatedBy	= @UserId
			,AffType	= @AffType
			,DeviceType = @DeviceType
		WHERE BannerId	= @BannerId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Add new size if not exists
	IF NOT EXISTS (SELECT 1 FROM dbo.BannerTypes WITH (NOLOCK) WHERE Type = 'Size' AND Value = @Size)
	BEGIN
		INSERT INTO dbo.BannerTypes (Type, Value)
		VALUES ('Size', @Size)
	END

	-- Remove old size if no banner uses
	IF NOT EXISTS (SELECT 1 FROM dbo.Banners WITH (NOLOCK) WHERE Size = @OldSize)
	BEGIN
		DELETE dbo.BannerTypes WITH (ROWLOCK, UPDLOCK)
		WHERE Type = 'Size' AND Value = @OldSize
	END

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData = 'BannerId=' + ISNULL(CONVERT(VARCHAR(10), @BannerId), '')
						+ ',' + 'FileName=' + ISNULL(@FileName, '')
						+ ',' + 'Category=' + ISNULL(@Category, '')
						+ ',' + 'Language=' + ISNULL(@Language, '')
						+ ',' + 'Currency=' + ISNULL(@Currency, '')
						+ ',' + 'ImageType=' + ISNULL(@ImageType, '')
						+ ',' + 'Size=' + ISNULL(@Size, '')
						+ ',' + 'AffType=' + ISNULL(CONVERT(VARCHAR(5), @AffType), '')
						+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(5), @DeviceType), '')
	
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