/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_alp" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_VerificationSuccessIns]
    @AffId			INT,
    @IpAddress  	NVARCHAR(25),
    @DeviceInfo  	NVARCHAR(100),
    @Language		VARCHAR(20) = 'en-US',
    @ErrCode		INT = 0 OUTPUT,
    @ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Verification - Insert new device when verifying successfully

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Parameter's Explanation:
*/

BEGIN
    SET NOCOUNT ON
    DECLARE @CurrentTime DATETIME
	SET @CurrentTime = GETDATE()

    BEGIN TRY
        INSERT INTO dbo.AffUserLoginInfo (AffId, IP, DeviceInfo, FailedLoginCount, LastLoginDate, VerificationCount, LastVerificationDate)
		VALUES (@AffId, @IpAddress, @DeviceInfo, 0, @CurrentTime, 1, @CurrentTime)

		UPDATE dbo.AffDetail WITH(ROWLOCK)
			SET LastLoginIP = @IpAddress, LastLoginDate = @CurrentTime
		WHERE AffId = @AffId 
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
        RETURN
    END CATCH
END

GO