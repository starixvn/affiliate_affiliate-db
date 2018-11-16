/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Upd]
	@UserId		INT,
	@PageId		SMALLINT,
	@PageName	NVARCHAR(200),
	@PageCode	NVARCHAR(100),
	@IP			NVARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Update

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
		@System		= 'AFFILIATE',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	SELECT @PageName = ISNULL(LTRIM(LTRIM(@PageName)), ''), @PageCode = ISNULL(LTRIM(LTRIM(@PageCode)), '')

	IF @PageName = '' OR @PageCode = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid input'
		RETURN
	END

	DECLARE @OldPageName NVARCHAR(200), @OldPageCode VARCHAR(100)
	SELECT  @OldPageName = PageName, @OldPageCode = PageCode FROM dbo.LandingPage WITH (NOLOCK) WHERE PageId = @PageId

	IF @OldPageName IS NULL
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This landing page does not exists'
		RETURN
	END

	IF @OldPageName = @PageName AND @OldPageCode = @PageCode
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This landing page does not changes'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0 AND PageId <> @PageId)
	BEGIN
		SELECT @ErrCode = 104, @ErrMsg = 'The landing page is already exists'
		RETURN
	END

	UPDATE dbo.LandingPage WITH (ROWLOCK, UPDLOCK)
	SET PageName = @PageName,
		PageCode = @PageCode
	WHERE PageId = @PageId

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 105, @ErrMsg = 'Insert failed'
		RETURN
	END

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData = 'PageName=' + @OldPageName + ',' + 'PageCode=' + @OldPageCode,
			@NewData = 'PageName=' + @PageName + ',' + 'PageCode=' + @PageCode
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO