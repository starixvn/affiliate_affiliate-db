/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_Login_ResultUpd]
	@AffId			INT,
    @IpAddress  	NVARCHAR(25),
	@DeviceInfo  	NVARCHAR(100),
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

	DECLARE @FailedLoginCount TINYINT

	DECLARE @CurrentTime DATETIME
	SET @CurrentTime = GETDATE()
	
	-- Login successful
	IF @IsSuccessful = 1
	BEGIN		
		-- Reset Failed Login Count
		SET @FailedLoginCount = 0
	END
	ELSE
	BEGIN
		SELECT @FailedLoginCount = ISNULL(FailedLoginCount, 0)
		FROM dbo.AffLoginByUserDevices WITH (NOLOCK)
		WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo
		
		IF @@ROWCOUNT = 0
		BEGIN
			SET @FailedLoginCount = 1
		END
		ELSE
		BEGIN
			SET @FailedLoginCount = @FailedLoginCount + 1
		END
	END

	-- Update login info
	BEGIN TRY
		IF(EXISTS (SELECT TOP 1 1 FROM dbo.AffLoginByUserDevices WITH (NOLOCK) WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo))
		BEGIN
			UPDATE dbo.AffLoginByUserDevices WITH (ROWLOCK, UPDLOCK)
			SET FailedLoginCount = @FailedLoginCount,
				LastLoginDate = @CurrentTime
			WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo
		END
		ELSE
		BEGIN
			INSERT INTO dbo.AffLoginByUserDevices (AffId, IP, DeviceInfo, FailedLoginCount, LastLoginDate)
			VALUES (@AffId, @IpAddress, @DeviceInfo, @FailedLoginCount, @CurrentTime)
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @NewData NVARCHAR(MAX)
	SELECT  @NewData = 
			'IsSuccessful='			+ ISNULL(CONVERT(VARCHAR(1), @IsSuccessful), '') + ',' +
			'FailedLoginCount='		+ ISNULL(CONVERT(VARCHAR(10), @FailedLoginCount), '') + ',' +
			'IP='					+ ISNULL(@IpAddress, '') + ',' +
			'DeviceInfo='			+ ISNULL(@DeviceInfo, '')

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @AffId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@NewData	= @NewData,
		@IP			= @IpAddress,
		@Language	= @Language
END
GO