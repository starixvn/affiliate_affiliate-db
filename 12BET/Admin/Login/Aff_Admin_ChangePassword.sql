/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_ChangePassword]
	@UserId	INT
	,@OldPwd	NVARCHAR(50)
	,@NewPwd	NVARCHAR(50)
	,@IP		NVARCHAR(40) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
*/

BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.Affiliate_User WITH (NOLOCK) WHERE CustId = @UserId AND UserPwd = @OldPwd)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Old password is incorrect'
		RETURN
	END

	IF ISNULL(@OldPwd, '') = ISNULL(@NewPwd, '')
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'New password must be different from old!'
		RETURN
	END

	BEGIN TRY
		UPDATE dbo.Affiliate_User WITH (ROWLOCK)
		SET UserPwd = @NewPwd
			,PwdExpiry = DATEADD(DAY, 30, GETDATE())
		WHERE CustId = @UserId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 103, @ErrMsg = 'Error occurs. Update unsuccessfully.'
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@IP		= @IP
END
GO