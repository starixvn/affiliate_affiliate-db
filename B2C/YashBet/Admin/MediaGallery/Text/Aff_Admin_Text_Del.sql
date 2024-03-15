/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Text_Del]
	@UserId			INT
	,@TextIds		VARCHAR(MAX)
	,@TargetId		TINYINT
	,@IP			VARCHAR(20) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Media Gallery - Text - Delete

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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

	-- Get banner info
	DECLARE @Texts TABLE (TextId INT, IsValid BIT)

	BEGIN TRY
		INSERT INTO @Texts (TextId, IsValid)
		SELECT s.val, CASE WHEN m.MediaId IS NULL THEN 0 ELSE 1 END
		FROM dbo.Aff_f_StringSplit (@TextIds, ',') s
			LEFT JOIN dbo.MediaGallery m WITH (NOLOCK)
				ON		s.val = m.MediaId
					AND m.ImageType = 'Text'
					AND (@TargetId = 0 OR m.TargetId = @TargetId)
		OPTION(MAXRECURSION 0)
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
						+ 'TextId=' + ISNULL(CONVERT(VARCHAR(10), m.MediaId), '')
						+ ',' + 'TargetId=' + ISNULL(CONVERT(VARCHAR(5), TargetId), '')
						+ ',' + 'FileName=' + ISNULL(m.FileName, '')
						+ ',' + 'Category=' + ISNULL(m.Categories, '')
						+ ',' + 'Language=' + ISNULL(m.Language, '')
						+ ',' + 'Currency=' + ISNULL(m.Currencies, '')
						+ ',' + 'DeviceType=' + ISNULL(m.DeviceTypes, '')
	FROM dbo.MediaGallery m WITH (NOLOCK)
		INNER JOIN @Texts tmp ON tmp.TextId = m.MediaId

	BEGIN TRY
		DELETE m WITH (ROWLOCK, UPDLOCK)
		FROM dbo.MediaGallery m
		WHERE EXISTS (SELECT 1 FROM @Texts tmp WHERE tmp.TextId = m.MediaId)
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