/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Ins]
	@UserId		INT,
	@PageName	NVARCHAR(200),
	@PageCode	NVARCHAR(100),
	@IP			NVARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin Site - Media Gallery - Landing Page - Insert

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
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

	-- Check exists
	IF EXISTS (SELECT 1 FROM dbo.LandingPage WITH (NOLOCK) WHERE PageName = @PageName AND PageCode = @PageCode AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'The landing page is already exists'
		RETURN
	END

	INSERT INTO dbo.LandingPage (PageName, PageCode, IsDeleted)
	VALUES (@PageName, @PageCode, 0)

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Insert failed'
		RETURN
	END

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT  @Data = 'PageName=' + @PageName + ',' + 'PageCode=' + @PageCode
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO