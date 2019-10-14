/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Del]
	@UserId			INT
	,@TextIds		VARCHAR(MAX)
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Text - Delete

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@System	= 'AFFILIATE'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Get banner info
	DECLARE @Texts TABLE (TextId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @Texts (TextId, IsValid)
		SELECT s.val, CASE WHEN b.BannerId IS NULL THEN 0 ELSE 1 END
		FROM dbo.strSplit (@TextIds, ',') s
			LEFT JOIN dbo.Banners_1 b WITH (NOLOCK) ON s.val = b.BannerId AND b.ImageType = 'Text'
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 101, @ErrMsg = 'Sorry, your input banner id is invalid. Please recheck it again.'
		RETURN
	END CATCH

	IF NOT EXISTS (SELECT 1 FROM @Texts)
		OR EXISTS (SELECT 1 FROM @Texts WHERE IsValid = 0)
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
						+ ',' + 'DeviceType=' + ISNULL(CONVERT(VARCHAR(5), b.DeviceType), '')
	FROM dbo.Banners_1 b WITH (NOLOCK)
		INNER JOIN @Texts tmp ON b.BannerId = tmp.TextId

	BEGIN TRY
		DELETE b WITH (ROWLOCK, UPDLOCK)
		FROM dbo.Banners_1 b
		WHERE EXISTS (SELECT 1 FROM @Texts tmp WHERE b.BannerId = tmp.TextId)
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