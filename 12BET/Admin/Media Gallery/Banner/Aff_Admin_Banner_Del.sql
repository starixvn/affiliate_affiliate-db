/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Del]
	@UserId			INT
	,@BannerIds		VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Banner - Delete

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

	-- Get banner info
	DECLARE @Banners TABLE (BannerId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @Banners (BannerId, IsValid)
		SELECT s.val, CASE WHEN b.BannerId IS NULL THEN 0 ELSE 1 END
		FROM dbo.strSplit (@BannerIds, ',') s
			LEFT JOIN dbo.Banners b WITH (NOLOCK) ON s.val = b.BannerId AND b.ImageType <> 'Text'
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Sorry, your input banner id is invalid. Please recheck it again.'
		RETURN
	END CATCH

	IF NOT EXISTS (SELECT 1 FROM @Banners)
		OR EXISTS (SELECT 1 FROM @Banners WHERE IsValid = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Sorry, your input banner id is invalid. Please recheck it again.'
		RETURN
	END

	DECLARE @OldData NVARCHAR(MAX)
	SELECT  @OldData = COALESCE(@OldData + ';', '')
						+ 'BannerId=' + ISNULL(CONVERT(VARCHAR(10), BannerId), '')
						+ ',' + 'FileName=' + ISNULL(FileName, '')
						+ ',' + 'ImageType=' + ISNULL(ImageType, '')
						+ ',' + 'Size=' + ISNULL(Size, '')
						+ ',' + 'Categories=' + ISNULL(Categories, '')
						+ ',' + 'Language=' + ISNULL(Language, '')
						+ ',' + 'Currencies=' + ISNULL(Currencies, '')
						+ ',' + 'AffTypes=' + ISNULL(AffTypes, '')
						+ ',' + 'DeviceTypes=' + ISNULL(DeviceTypes, '')
	FROM dbo.Banners b WITH (NOLOCK)
	WHERE ImageType <> 'Text'
		AND EXISTS (SELECT 1 FROM @Banners tmp WHERE b.BannerId = tmp.BannerId)

	BEGIN TRY
		DELETE b WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Banners b
		WHERE EXISTS (SELECT 1 FROM @Banners tmp WHERE b.BannerId = tmp.BannerId)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@IP		= @IP
		,@Language	= 'en-US'
END
GO