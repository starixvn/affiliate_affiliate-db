/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Login]
	@UserId			INT = 0 OUTPUT
	,@UserName		VARCHAR(50)
	,@UserPwd		VARCHAR(100)
	,@HostName		NVARCHAR(200)
	,@IP			VARCHAR(50)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Login

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(MAX)
	DECLARE @FailedCount INT

	IF ISNULL(@UserName, '') = '' OR ISNULL(@UserPwd, '') = ''
	BEGIN
		SELECT @LogData = @LogData + 'Failed(User_Not_Found)'
	END

	SELECT	@UserId = custid
			,@LogData = CASE
							WHEN UserPwd <> @UserPwd THEN 'Failed(Password)'
							WHEN Closed = 1 THEN 'Failed(A/C_Closed)'
							END
			,@FailedCount = ISNULL(FailedLoginCount, 0)
	FROM dbo.Users WITH (NOLOCK)
	WHERE Username = @UserName

	IF ISNULL(@UserId, 0) = 0
	BEGIN
		SELECT @LogData = @LogData + 'Failed(User_Not_Found)'
	END

	IF @LogData IS NOT NULL -- Login Failed
	BEGIN
		IF @LogData = 'Failed(A/C_Closed)'
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Account closed. Please contact your administrator!'
		END
		ELSE
		BEGIN
			SELECT @ErrCode = 102

			IF @FailedCount < 5
			BEGIN
				UPDATE dbo.Users WITH (ROWLOCK)
				SET FailedLoginCount = @FailedCount + 1
				WHERE custid = @UserId

				SELECT @ErrMsg = 'Wrong username or password.'
			END
			ELSE
			BEGIN
				UPDATE dbo.Users WITH (ROWLOCK)
				SET Closed = 1
				WHERE custid = @UserId

				SELECT @ErrMsg = 'Your account is closed due to 5 wrong password attempts'

				-- Reset LogData
				SET @LogData = 'The A/C is closed due to 5 wrong password attempts'
			END
		END
	END
	ELSE -- Login Successful
	BEGIN
		UPDATE dbo.Users WITH (ROWLOCK)
		SET FailedLoginCount = 0
			,LastLoginIP = @IP
			,LastLoginDate = GETDATE()
		WHERE custid = @UserId

		SET @LogData = 'Success'
	END

	SELECT @LogData = 'Admin:' + @Username + ' IP:' + ISNULL(@IP, '') + ' Result:' + @LogData + ' From:' + ISNULL(@HostName, '')

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @LogData,
		@IP			= @IP,
		@Language	= 'en-US'
END
GO