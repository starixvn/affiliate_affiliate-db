/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Login_ResultUpd]
	@AffId			INT,
	@LoginIP		NVARCHAR(20),
	@Language		VARCHAR(20) = 'en-US',
	@IsSuccessful	BIT,
	@SessionId		VARCHAR(50),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Login - Update user info after login

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190115@Walter: Remove Locking action [RedmineID: #104884]
*/

BEGIN
	SET NOCOUNT ON

	-- For log
	DECLARE @LogData NVARCHAR(2000)

	DECLARE @CurrentTime DATETIME
	SELECT  @CurrentTime = GETDATE()

	DECLARE @IsLocked			BIT,
			@FailedLoginCount	TINYINT,
			@LastLoginDate		DATETIME

	SELECT
		@IsLocked = ISNULL(ai.IsLocked, 0),
		@LastLoginDate = ISNULL(ad.LastLoginDate, @CurrentTime)
	FROM AffInfo ai WITH (NOLOCK)
		INNER JOIN AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
	WHERE ai.AffID = @AffId
	
	-- Login successful
	IF @IsSuccessful = 1
	BEGIN
		-- Unlock user  
		IF ISNULL(@IsLocked, 0) = 1
		BEGIN
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET IsLocked = 0
			WHERE AffID = @AffId
		END
		
		-- Reset Failed Login Count
		SELECT @FailedLoginCount = 0

		-- Log
		SELECT @LogData = 'Successful Login, ServerID: ' + @SessionId
	END
	ELSE
	BEGIN
		SELECT @FailedLoginCount = ISNULL(FailedLoginCount, 0)
		FROM dbo.AffLoginInfo WITH (NOLOCK)
		WHERE AffID = @AffId AND LoginSessionId = @SessionId
		
		IF @@ROWCOUNT = 0
		BEGIN
			SET @FailedLoginCount = 1

			INSERT INTO dbo.AffLoginInfo (AffId, LoginSessionId, LastLoginDate, LastLoginIP, FailedLoginCount)
			VALUES (@AffId, @SessionId, @CurrentTime, @LoginIP, 1)
		END
		ELSE
		BEGIN
			SELECT @FailedLoginCount = @FailedLoginCount + 1

			-- If Failed Login Count > 5, lock user
			IF @FailedLoginCount > 5
			BEGIN
				UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
				SET IsLocked = 1
				WHERE AffID = @AffId
			END
		END

		-- Log
		SELECT @LogData = 'Failed Login, ServerID: ' + @SessionId
	END

	BEGIN TRY
		-- Update login info
		UPDATE dbo.AffLoginInfo WITH (ROWLOCK, UPDLOCK)
		SET FailedLoginCount = @FailedLoginCount,
			LastLoginIP = @LoginIP,
			LastLoginDate = @CurrentTime
		WHERE AffID = @AffId AND LoginSessionId = @SessionId
		
		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET LastLoginDate = @CurrentTime,
			LoginCount = @FailedLoginCount,
			LastLoginIP = @LoginIP
		WHERE AffID = @AffId
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 102, @ErrMsg = ERROR_MESSAGE()

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 
			'IsSuccessful='			+ ISNULL(CONVERT(VARCHAR(1), @IsSuccessful), '') + ',' +
			'FailedLoginCount='		+ ISNULL(CONVERT(VARCHAR(10), @FailedLoginCount), '') + ',' +
			'LoginIP='				+ ISNULL(@LoginIP, '') + ',' +
			'LoginSessionId='		+ ISNULL(@SessionId, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @LoginIP,
		@Language	= @Language
END
GO