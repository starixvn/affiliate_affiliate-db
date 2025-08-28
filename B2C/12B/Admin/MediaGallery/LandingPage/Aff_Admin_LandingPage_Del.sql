/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_LandingPage_Del]
	@UserId		INT,
	@PageIds	VARCHAR(MAX),
	@IP			VARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin Site - Media Gallery - Landing Page - Delete

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250721@Eddie: Add new condition [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'
		   ,@Default_PageId SMALLINT

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF ISNULL(@PageIds, '') = ''
		RETURN

	DECLARE @LandingPage TABLE (PageId SMALLINT)
	
	-- Default pagecode
	SELECT @Default_PageId = CONVERT(SMALLINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'LandingPage'

	UPDATE lp WITH (ROWLOCK, UPDLOCK)
	SET lp.IsDeleted = 1
	OUTPUT DELETED.PageId INTO @LandingPage (PageId)
	FROM dbo.LandingPage lp
	WHERE EXISTS (SELECT 1 FROM dbo.Aff_f_StringSplit (@PageIds, ',') f WHERE lp.PageId = f.val AND lp.PageId <> @Default_PageId) -- Default pagecode must not be deleted
		AND lp.IsDeleted = 0
	OPTION(MAXRECURSION 0)

	IF @@ROWCOUNT = 0
		RETURN

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX)

	SELECT  @OldData = COALESCE(@OldData + ',', '') + CONVERT(VARCHAR(10), PageId)
	FROM @LandingPage

	SELECT  @OldData = 'PageId=' + @OldData
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@IP			= @IP,
		@Language	= @Language
END
GO