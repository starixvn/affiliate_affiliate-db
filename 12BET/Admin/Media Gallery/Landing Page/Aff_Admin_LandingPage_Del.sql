/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language VARCHAR(10) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Media]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

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

	SELECT  @OldData = CONVERT(NVARCHAR(MAX),(SELECT PageId AS '@PageId' FROM @LandingPage FOR XML PATH('row'), ROOT('root')))

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@IP			= @IP,
		@Language	= @Language
END
GO