/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Component_Ins]
    @ComponentTypeId   INT,
    @ComponentName     VARCHAR(200),
    @ComponentCode     VARCHAR(200),
    @UserId            INT,
    @StatusId         TINYINT = 1,
    @IP               VARCHAR(50) = '',
    @ComponentId      INT = 0 OUTPUT,
    @ErrCode          INT = 0 OUTPUT,
    @ErrMsg           NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Insert new Landing Page Component
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TimeZone        TINYINT
          , @CurrentDate     DATETIME
          , @Language        NVARCHAR(5) = 'en-US'
          , @StartTime       DATETIME = GETDATE()
          , @EndTime         DATETIME
          , @Duration        INT
          , @SPName          VARCHAR(200) = OBJECT_NAME(@@PROCID)
          , @NewData         NVARCHAR(MAX);

    --Check permission
    EXEC dbo.Aff_Con_CheckPermission @CustID = @UserId
                                    ,@FuncName = '[ComponentManagement]'
                                    ,@ErrCode = @ErrCode OUTPUT
                                    ,@ErrMsg = @ErrMsg OUTPUT;
    
    IF @ErrCode <> 0
        RETURN;

    -- Validate input
    BEGIN
        SELECT @ComponentName = LTRIM(RTRIM(@ComponentName));
        SELECT @ComponentCode = LTRIM(RTRIM(@ComponentCode));

        IF ISNULL(@ComponentName, '') = ''
        BEGIN
            SELECT @ErrCode = 1001
                 , @ErrMsg = N'Component Name is required.';
            RETURN;
        END

        IF ISNULL(@ComponentCode, '') = ''
        BEGIN
            SELECT @ErrCode = 1002
                 , @ErrMsg = N'Component Code is required.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.LandingPage_Component WITH (NOLOCK) 
                  WHERE ComponentName = @ComponentName)
        BEGIN
            SELECT @ErrCode = 1003
                 , @ErrMsg = N'Component Name already exists.';
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM dbo.LandingPage_Component WITH (NOLOCK) 
                  WHERE ComponentCode = @ComponentCode)
        BEGIN
            SELECT @ErrCode = 1004
                 , @ErrMsg = N'Component Code already exists.';
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.LandingPage_ComponentType WITH (NOLOCK) 
                      WHERE ComponentTypeId = @ComponentTypeId)
        BEGIN
            SELECT @ErrCode = 1005
                 , @ErrMsg = N'Invalid Component Type.';
            RETURN;
        END
    END

    -- Get timezone
    SELECT @TimeZone = CONVERT(TINYINT, SValue)
    FROM dbo.SystemSettings WITH (NOLOCK)
    WHERE SName = 'TimeZone';

    SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());

    BEGIN TRY
        INSERT INTO dbo.LandingPage_Component
        (
            ComponentTypeId,
            ComponentName,
            ComponentCode,
            Creator,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            StatusId
        )
        VALUES
        (
            @ComponentTypeId,
            @ComponentName,
            @ComponentCode,
            @UserId,
            @CurrentDate,
            @UserId,
            @CurrentDate,
            @StatusId
        );

        SELECT @ComponentId = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = 1010
             , @ErrMsg = N'Error occurs. Insert unsuccessfully.';
        RETURN;
    END CATCH

    -- Write log
    SELECT @EndTime = GETDATE();
    SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

    SELECT @NewData = (
            SELECT @ComponentId AS 'ci'
                  ,@ComponentCode AS 'cc'
                  ,@ComponentName AS 'cn'
                  ,@ComponentTypeId AS 'ct'
                  ,@StatusId AS 'st'
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
        @UserId    = @UserId
        ,@AffId    = 0
        ,@SPName   = @SPName
        ,@NewData  = @NewData
        ,@IP       = @IP
        ,@Language = @Language
        ,@Duration = @Duration;

END