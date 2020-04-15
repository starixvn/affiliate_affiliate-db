/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Banner_Del]
	@UserId			INT
	,@BannerIds		VARCHAR(MAX)
	,@TargetId		TINYINT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Media Gallery - Banner - Delete

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

	Param's Explanation:
		- @TargetId:
			1: Member banner
			2: Affiliate banner
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
		SELECT s.val, CASE WHEN m.MediaId IS NULL THEN 0 ELSE 1 END
		FROM dbo.Aff_f_StringSplit (@BannerIds, ',') s
			LEFT JOIN dbo.MediaGallery m WITH (NOLOCK)
				ON		s.val = m.MediaId
					AND m.ImageType = 'Image'
					AND (@TargetId = 0 OR m.TargetId = @TargetId)
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
						+ 'BannerId=' + ISNULL(CONVERT(VARCHAR(10), m.MediaId), '')
						+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(10), m.TargetId), '')
						+ ',' + 'FileName=' + ISNULL(m.FileName, '')
						+ ',' + 'Size=' + ISNULL(m.Size, '')
						+ ',' + 'Categories=' + ISNULL(m.Categories, '')
						+ ',' + 'Language=' + ISNULL(m.Language, '')
						+ ',' + 'Currencies=' + ISNULL(m.Currencies, '')
						+ ',' + 'AffTypes=' + ISNULL(m.AffTypes, '')
						+ ',' + 'DeviceTypes=' + ISNULL(m.DeviceTypes, '')
	FROM dbo.MediaGallery m WITH (NOLOCK)
		INNER JOIN @Banners tmp ON tmp.BannerId = m.MediaId

	BEGIN TRY
		DELETE m WITH (ROWLOCK, UPDLOCK)
		FROM dbo.MediaGallery m
		WHERE EXISTS (SELECT 1 FROM @Banners tmp WHERE tmp.BannerId = m.MediaId)
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Delete unsuccessfully.'
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