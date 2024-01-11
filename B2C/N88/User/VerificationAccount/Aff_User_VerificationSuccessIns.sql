/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_VerificationSuccessIns]
    @AffId			INT,
    @IpAddress  	NVARCHAR(25),
    @DeviceInfo  	NVARCHAR(100),
    @Language		VARCHAR(20) = 'en-US',
    @ErrCode		INT = 0 OUTPUT,
    @ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Creator: 20190304@Walter
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Verification - Insert new device when verifying successfully

	Revisions:
		- 20190304@Walter: Initiliaze SP [RedmineID: #104884]
		- 20221101@Malcolm: Update login information [RedmineID: #177552]

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