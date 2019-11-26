/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_ChangePassword]
	@UserId		INT
	,@CustId	INT
	,@OldPwd	NVARCHAR(50) = NULL
	,@NewPwd	NVARCHAR(50)
	,@IP		NVARCHAR(40) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - User Password - Change password

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @username VARCHAR(30)
	SELECT  @username = username FROM dbo.Affiliate_User WITH (NOLOCK) WHERE CustId = @CustId

	IF @username IS NULL
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'Invalid user!'
		RETURN
	END

	IF @OldPwd IS NOT NULL -- @UserId = @CustId -- Update owner
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM dbo.Affiliate_User WITH (NOLOCK) WHERE CustId = @CustId AND UserPwd = @OldPwd)
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Old password is incorrect!'
			RETURN
		END

		IF ISNULL(@OldPwd, '') = ISNULL(@NewPwd, '')
		BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'New password must be different from old!'
			RETURN
		END
	END
	ELSE
	BEGIN
		EXEC dbo.Aff_Con_CheckPermission
			@CustId		= @UserId
			,@FuncName	= '[UserControl]'
			,@System	= 'AFFILIATE'
			,@ErrCode	= @ErrCode OUTPUT
			,@ErrMsg	= @ErrMsg OUTPUT
    
		IF @ErrCode <> 0
			RETURN
	END

	BEGIN TRY
		UPDATE dbo.Affiliate_User WITH (ROWLOCK)
		SET UserPwd = @NewPwd
			,PwdExpiry = DATEADD(DAY, 30, GETDATE())
		WHERE CustId = @CustId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	SELECT  @NewData = 'Update password of user ' + @username + ' (' + CONVERT(VARCHAR(20), @CustId) + ')'
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
END
GO