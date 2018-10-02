/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Del]
	@UserId		INT,
	@PageIds	VARCHAR(MAX),
	@IP			NVARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Delete

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[MEDIA]',
		@System		= 'AFFILIATE',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	
	IF ISNULL(@PageIds, '') = ''
		RETURN

	DECLARE @LandingPage TABLE (PageId SMALLINT)

	UPDATE lp WITH (ROWLOCK, UPDLOCK)
	SET lp.IsDeleted = 1
	OUTPUT DELETED.PageId INTO @LandingPage (PageId)
	FROM dbo.LandingPage lp
	WHERE EXISTS (SELECT 1 FROM dbo.Aff_f_StringSplit (@PageIds, ',') f WHERE lp.PageId = f.val)
		AND lp.IsDeleted = 0

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
		@Language	= 'E'
END
GO