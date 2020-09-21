/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_VerificationUpd]
	@AffId			INT,
    @IpAddress  	NVARCHAR(25),
	@DeviceInfo  	NVARCHAR(100),
	@Language		VARCHAR(20) = 'en-US',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(2000) = '' OUTPUT
AS

/*
	Creator: 20190301@Walter
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Verification - Update VerificationCount and LastVerificationDate

	Revisions:
		- 20190301@Walter: Initiliaze SP [RedmineID: #104884]

	Parameter's Explanation:
*/

BEGIN
	SET NOCOUNT ON

    DECLARE @VerificationCount TINYINT
	DECLARE @CurrentTime DATETIME
	SET @CurrentTime = GETDATE()

    SELECT @VerificationCount = ISNULL(VerificationCount, 0)
		FROM dbo.AffUserLoginInfo WITH (NOLOCK)
		WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo

    IF(EXISTS (SELECT TOP 1 1 FROM dbo.AffUserLoginInfo WITH (NOLOCK) WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo))
    BEGIN
        BEGIN TRY
            UPDATE dbo.AffUserLoginInfo WITH (ROWLOCK, UPDLOCK)
                SET VerificationCount = @VerificationCount + 1,
                    LastVerificationDate = @CurrentTime
                WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo
        END TRY
        BEGIN CATCH
            SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
            RETURN
        END CATCH
    END

    -- Write log
     BEGIN
         DECLARE @SPName VARCHAR(200)
         SELECT  @SPName = OBJECT_NAME(@@PROCID)

         DECLARE @NewData NVARCHAR(MAX)
         SELECT  @NewData = 
                 'VerificationCount='	+ ISNULL(CONVERT(VARCHAR(10), @VerificationCount), '') + ',' +
                 'IP='					+ ISNULL(@IpAddress, '') + ',' +
                 'DeviceInfo='			+ ISNULL(@DeviceInfo, '')

         EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
             @UserId	= @AffId,
             @AffId		= @AffId,
             @SPName	= @SPName,
             @NewData	= @NewData,
             @IP		= @IpAddress,
             @Language	= @Language
     END
END
GO