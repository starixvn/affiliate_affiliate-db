/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Login_ResultUpd]
	@AffId      	INT,
    @IpAddress  	NVARCHAR(25),
    @OS         	NVARCHAR(50),
    @Browser    	NVARCHAR(20) = NULL,
    @UserAgent  	NVARCHAR(256) = NULL,
	@Language		VARCHAR(20) = 'en-US',
	@IsSuccessful	BIT,
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
		- 20190125@Walter: Store user device info [RedmineID: #104884]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LogData NVARCHAR(2000)
	DECLARE @FailedLoginCount	TINYINT

	DECLARE @CurrentTime DATETIME
	SELECT  @CurrentTime = GETDATE()
	
	-- Login successful
	IF @IsSuccessful = 1
	BEGIN		
		-- Reset Failed Login Count
		SELECT @FailedLoginCount = 0
		-- Log
		SELECT @LogData = 'Successful Login, IpAddress: ' + @IpAddress
	END
	ELSE
	BEGIN
		SELECT @FailedLoginCount = ISNULL(FailedLoginCount, 0)
		FROM dbo.AffLoginByUserDevices WITH (NOLOCK)
		WHERE AffId = @AffId AND IpAddress = @IpAddress AND OS = @OS
		
		IF @@ROWCOUNT = 0
		BEGIN
			SET @FailedLoginCount = 1
		END
		ELSE
		BEGIN
			SELECT @FailedLoginCount = @FailedLoginCount + 1
		END

		-- Log
		SELECT @LogData = 'Failed Login, IpAddress: ' + @IpAddress
	END

	-- Update login info
	BEGIN TRY
		IF(EXISTS (SELECT TOP 1 1 FROM dbo.AffLoginByUserDevices WITH (NOLOCK) WHERE AffId = @AffId AND IpAddress = @IpAddress AND OS = @OS))
		BEGIN
			INSERT INTO dbo.AffLoginByUserDevices (AffId, IpAddress, OS, Browser, UserAgent, FailedLoginCount, LastLoginDate)
			VALUES (@AffId, @IpAddress, @OS, @Browser, @UserAgent, @FailedLoginCount, @CurrentTime)
		END
		ELSE
		BEGIN
			UPDATE dbo.AffLoginByUserDevices WITH (ROWLOCK, UPDLOCK)
			SET FailedLoginCount = @FailedLoginCount,
				LastLoginDate = @CurrentTime,
				Browser = @Browser,
				UserAgent = @UserAgent
			WHERE AffId = @AffId AND IpAddress = @IpAddress AND OS = @OS
		END
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
			'IpAddress='			+ ISNULL(@IpAddress, '') + ',' +
			'OS='					+ ISNULL(@OS, '') + ',' +
			'Browser='				+ ISNULL(@Browser, '') + ',' +
			'UserAgent='			+ ISNULL(@UserAgent, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IpAddress,
		@Language	= @Language
END
GO