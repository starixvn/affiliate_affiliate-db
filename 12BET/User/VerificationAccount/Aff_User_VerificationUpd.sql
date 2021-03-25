/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

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
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Verification - Update VerificationCount and LastVerificationDate

	Revisions:
		- 20190301@Walter: Initiliaze SP [RedmineID: #104884]
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]

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
				
			SET @VerificationCount = @VerificationCount + 1
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
		 SELECT @NewData = CONVERT(NVARCHAR(MAX), 
						   (
		 						SELECT @VerificationCount AS '@VerificationCount'
		 							,@IpAddress AS '@IP'
		 							,@DeviceInfo AS '@DeviceInfo'
		 						FOR XML PATH('row'), ROOT('root')
		 				   ))
		 
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