/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_SignUp]
    @Username VARCHAR(50),
    @Email VARCHAR(100) = '',
    @PhoneNo VARCHAR(20) = '',
    @CurrencyId INT = 0,
    @AreaCode VARCHAR(10) = '',
    @AffCode VARCHAR(50) = '',
    @CaptchaType INT = 0,
    @ReCaptchaToken NVARCHAR(MAX) = '',
    @AffClickId VARCHAR(100) = '',
    @ReferralUrl NVARCHAR(500) = '',
    @UserLang NVARCHAR(5) = '',
    @Status VARCHAR(100) = '',
    @Duration INT = 0,
    @ExtData NVARCHAR(MAX) = '',
    @APITraceId VARCHAR(100) = '',
    @APIErrorCode VARCHAR(100) = '',
    @APIMessage NVARCHAR(MAX) = '',
    @ApiUrl NVARCHAR(500) = '',
    @SignUpUrl NVARCHAR(500) = '',
    @UserAgent NVARCHAR(500) = '',
    @IP VARCHAR(50) = '',
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created: 20250910@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: API Sign Up endpoint logging [RedmineID: #236797]
    Revisions:
        - 20250910@Sophia: Initial version [RedmineID: #236797]
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @LogData NVARCHAR(MAX);

    -- =========================
    -- This SP for Write log only
    -- =========================
    IF @Duration = 0
    BEGIN
        DECLARE @EndTime DATETIME = GETDATE();
        SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);
    END;

    -- Compose @LogData JSON
    SELECT @LogData = (
        SELECT @Username AS 'u'
              ,@Email AS 'e'
              ,@PhoneNo AS 'ph'
              ,@CurrencyId AS 'cu'
              ,@AreaCode AS 'ac'
              ,@AffCode AS 'afc'
              ,@CaptchaType AS 'ct'
              ,LEFT(@ReCaptchaToken, 100) AS 'rct'  -- Truncate long token for logging
              ,@AffClickId AS 'cl'
              ,@ReferralUrl AS 'ru'
              ,@UserLang AS 'l'
              ,@Status AS 'st'
              ,@Duration AS 'dur'
              ,@ExtData AS 'ext'
              ,@APITraceId AS 'tid'
              ,@APIErrorCode AS 'ec'
              ,@APIMessage AS 'msg'
              ,@ApiUrl AS 'url'
              ,@SignUpUrl AS 'su'
              ,@UserAgent AS 'ua'
              ,@IP AS 'ip'
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    -- Write log
    DECLARE @SPName VARCHAR(200);
    SELECT @SPName = OBJECT_NAME(@@PROCID);
    
    EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
        @UserId     = 0,
        @AffId      = 0,
        @SPName     = @SPName,
        @NewData    = @LogData,
        @IP         = @IP,
        @Language   = @UserLang,
        @Duration   = @Duration;
END;
GO
