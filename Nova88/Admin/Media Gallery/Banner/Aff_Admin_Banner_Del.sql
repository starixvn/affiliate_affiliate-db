/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Del]
	@UserId			INT
	,@BannerIds		VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Admin - Media Gallery - Banner - Delete

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

	-- Get banner info
	DECLARE @Banners TABLE (BannerId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @Banners (BannerId, IsValid)
		SELECT s.val, CASE WHEN b.BannerId IS NULL THEN 0 ELSE 1 END
		FROM dbo.Aff_f_StringSplit (@BannerIds, ',') s
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
	SELECT  @OldData = COALESCE(@OldData + ' - ', '')
						+ 'BannerId=' + ISNULL(CONVERT(VARCHAR(10), b.BannerId), '')
						+ ',' + 'FileName=' + ISNULL(b.FileName, '')
						+ ',' + 'Category=' + ISNULL(b.Category, '')
						+ ',' + 'Language=' + ISNULL(b.Language, '')
						+ ',' + 'Currency=' + ISNULL(b.Currency, '')
						+ ',' + 'ImageType=' + ISNULL(b.ImageType, '')
						+ ',' + 'Size=' + ISNULL(b.Size, '')
						+ ',' + 'AffType=' + ISNULL(CONVERT(VARCHAR(5), b.AffType), '')
						+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(5), b.DeviceType), '')
	FROM dbo.Banners b WITH (NOLOCK)
		INNER JOIN @Banners tmp ON b.BannerId = tmp.BannerId

	BEGIN TRY
		DELETE b WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Banners b
		WHERE EXISTS (SELECT 1 FROM @Banners tmp WHERE b.BannerId = tmp.BannerId)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
		RETURN
	END CATCH

	-- Remove old size if no banner uses
	DELETE bt WITH (ROWLOCK, UPDLOCK)
	FROM dbo.BannerTypes bt
	WHERE bt.Type = 'Size'
		AND NOT EXISTS (SELECT 1 FROM dbo.Banners b WITH (NOLOCK) WHERE bt.Value = b.Size)

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