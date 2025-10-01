/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Component_Upd]
    @UserId          INT,
    @ComponentId     INT,
    @ComponentName   VARCHAR(200) = NULL,
    @ComponentTypeId INT,
    @StatusId        TINYINT = NULL,
    @IP             VARCHAR(50) = '',
    @ErrCode        INT = 0 OUTPUT,
    @ErrMsg         NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Update Landing Page Component
    
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]

    Param's Explanation:
        - @ComponentName:
            + NULL   : no change will be made to the existing value
            + ''     : sets the value to an empty string
            + 'abc'  : updates the field with the provided input
        - @StatusId:
            + NULL   : no change will be made to the existing value
            + 0      : Inactive
            + 1      : Active
*/
BEGIN
    SET NOCOUNT ON;

    DECLARE @TimeZone     TINYINT
          , @CurrentDate  DATETIME
          , @Language     NVARCHAR(5) = 'en-US'
          , @StartTime    DATETIME = GETDATE()
          , @EndTime      DATETIME
          , @Duration     INT
          , @SPName       VARCHAR(200) = OBJECT_NAME(@@PROCID)
          , @OldData      NVARCHAR(MAX)
          , @NewData      NVARCHAR(MAX);

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

        IF @ComponentName = ''
        BEGIN
            SELECT @ErrCode = 1001
                 , @ErrMsg = N'Component Name is required.';
            RETURN;
        END

        IF EXISTS (
            SELECT 1 
            FROM dbo.LandingPage_Component WITH (NOLOCK)
            WHERE ComponentName = @ComponentName 
            AND ComponentId <> @ComponentId
            AND ComponentTypeId = ISNULL(@ComponentTypeId, ComponentTypeId)
        )
        BEGIN
            SELECT @ErrCode = 1002
                 , @ErrMsg = N'Component Name already exists.';
            RETURN;
        END

        IF @ComponentTypeId IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.LandingPage_ComponentType WITH (NOLOCK)
            WHERE ComponentTypeId = @ComponentTypeId
        )
        BEGIN
            SELECT @ErrCode = 1005
                 , @ErrMsg = N'Invalid Component Type.';
            RETURN;
        END
    END

    -- Old data for writing log
    SELECT @OldData = (
        SELECT c.ComponentId AS 'ci'
              ,c.ComponentCode AS 'cc'
              ,c.ComponentName AS 'cn'
              ,c.ComponentTypeId AS 'ct'
              ,c.StatusId AS 'st'
        FROM dbo.LandingPage_Component c WITH (NOLOCK)
        WHERE c.ComponentId = @ComponentId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    -- Get timezone
    SELECT @TimeZone = CONVERT(TINYINT, SValue)
    FROM dbo.SystemSettings WITH (NOLOCK)
    WHERE SName = 'TimeZone';

    SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());

    BEGIN TRY
        UPDATE c WITH (ROWLOCK, UPDLOCK)
        SET c.ComponentName   = ISNULL(@ComponentName, c.ComponentName)
           ,c.ComponentTypeId = ISNULL(@ComponentTypeId, c.ComponentTypeId)
           ,c.StatusId       = ISNULL(@StatusId, c.StatusId)
           ,c.UpdatedBy      = @UserId
           ,c.UpdatedDate    = @CurrentDate
        FROM dbo.LandingPage_Component c
        WHERE c.ComponentId = @ComponentId;

    END TRY
    BEGIN CATCH
        SELECT @ErrCode = 1011
             , @ErrMsg = N'Error occurs. Update unsuccessfully.';
        RETURN;
    END CATCH

    -- Write log
    SELECT @EndTime = GETDATE();
    SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime);

    SELECT @NewData = (
        SELECT c.ComponentId AS 'ci'
              ,c.ComponentCode AS 'cc'
              ,c.ComponentName AS 'cn'
              ,c.ComponentTypeId AS 'ct'
              ,c.StatusId AS 'st'
        FROM dbo.LandingPage_Component c WITH (NOLOCK)
        WHERE c.ComponentId = @ComponentId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
        @UserId    = @UserId
        ,@AffId    = 0
        ,@SPName   = @SPName
        ,@OldData  = @OldData
        ,@NewData  = @NewData
        ,@IP       = @IP
        ,@Language = @Language
        ,@Duration = @Duration;
END