/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Login]
	@UserId			INT = 0 OUTPUT
	,@UserName		VARCHAR(50)
	,@UserPwd		VARCHAR(50)
	,@HostName		NVARCHAR(200)
	,@IP			VARCHAR(20)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Login

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @LogData NVARCHAR(MAX) = ''
	DECLARE @FailedCount INT

	SELECT	@UserId = custid
			,@LogData = CASE	WHEN RoleId NOT BETWEEN 5 AND 10 THEN 'Failed(Not_Admin)'
								WHEN UserPwd <> @UserPwd THEN 'Failed(Password)'
								WHEN Closed = 1 THEN 'Failed(A/C_Closed)'
								END
			,@FailedCount = ISNULL(LoginCount, 0)
	FROM dbo.Affiliate_User u WITH (NOLOCK)
	WHERE Username = @UserName

	IF ISNULL(@UserId, 0) = 0
	BEGIN
		SELECT @LogData = 'Failed(User_Not_Found)'
	END

	IF @LogData IS NOT NULL -- Login Failed
	BEGIN
		IF @LogData = 'Failed(A/C_Closed)'
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Account closed. Please contact your administrator!'
		END
		ELSE
		BEGIN
			IF @FailedCount < 5
			BEGIN
				UPDATE dbo.Affiliate_User WITH (ROWLOCK)
				SET LoginCount = @FailedCount + 1
				WHERE custid = @UserId
			END
			ELSE
			BEGIN
				UPDATE dbo.Affiliate_User WITH (ROWLOCK)
				SET Closed = 1
				WHERE custid = @UserId

				-- Reset LogData
				SET @LogData = 'The A/C is closed due to 5 wrong password attempts'
			END

			SELECT @ErrCode = 102, @ErrMsg = 'Wrong username or password.'
		END
	END
	ELSE -- Login Successful
	BEGIN
		UPDATE dbo.Affiliate_User WITH (ROWLOCK)
		SET LoginCount = 0
			,IPLogin = @IP
			,LastLogged = GETDATE()
			,On_SessionId = 0
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