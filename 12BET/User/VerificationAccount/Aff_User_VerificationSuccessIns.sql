/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_VerificationSuccessIns]
    @AffId			INT,
    @IpAddress  	VARCHAR(50),
    @DeviceInfo  	NVARCHAR(100),
    @Language		VARCHAR(20) = 'en-US',
    @ErrCode		INT = 0 OUTPUT,
    @ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Creator: 20190304@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Verification - Insert new device when verifying successfully

	Revisions:
		- 20190304@Walter: Initiliaze SP [RedmineID: #104884]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

	Parameter's Explanation:
*/

BEGIN
    SET NOCOUNT ON
    DECLARE @CurrentTime DATETIME
	SET @CurrentTime = GETDATE()

    BEGIN TRY
        INSERT INTO dbo.AffUserLoginInfo (AffId, IP, DeviceInfo, FailedLoginCount, LastLoginDate, VerificationCount, LastVerificationDate)
			VALUES (@AffId, @IpAddress, @DeviceInfo, 0, @CurrentTime, 1, @CurrentTime)
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
        RETURN
    END CATCH
END

GO