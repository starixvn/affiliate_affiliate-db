/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Del]
	@UserId			INT,
	@GroupId		INT,
	@IP				NVARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Add new commission group

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[CommissionGroup]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)

		RETURN
	END

	-- Check group is being used
	IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- At least 1 affiliate was assigned to this group. You cannot delete it.
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1008, @Language)

		RETURN
	END

	BEGIN TRY
		UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		SET IsDeleted = 1
		WHERE GroupId = @GroupId
	END TRY
	BEGIN CATCH
		-- Failed to delete group! Please try again!
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1010, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT @Data = '<root><row GroupId="'+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') +'"></row></root>'
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO