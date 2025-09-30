/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Deal_Upd]
    @UserId      INT,
    @DealId      INT,
    @StatusId    TINYINT = NULL,
    @IP          VARCHAR(50) = '',
    @ErrCode     INT = 0 OUTPUT,
    @ErrMsg      NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created: 20250929@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Update Landing Page Deal Status
    
    Revisions:
        - 20250929@Sophia: Initial version [RedmineID: #239988]

    Param's Explanation:
        - @StatusId:
            + NULL   : no change will be made to the existing value
            + 0      : Inactive
            + 1      : Active
            + 2      : Include deleted deals
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
          , @NewData      NVARCHAR(MAX)
          , @DealName     NVARCHAR(100);

    -- Check permission
    EXEC dbo.Aff_Con_CheckPermission 
        @CustID = @UserId
        ,@FuncName = '[ComponentManagement]'
        ,@ErrCode = @ErrCode OUTPUT
        ,@ErrMsg = @ErrMsg OUTPUT;
    
    IF @ErrCode <> 0
        RETURN;

    -- Validate input
    BEGIN
        -- Check if Deal exists and get DealName
        SELECT @DealName = cg.GroupName
        FROM dbo.LandingPage_Deal ld WITH (NOLOCK)
        INNER JOIN dbo.CommGroup cg WITH (NOLOCK) 
            ON ld.DealId = cg.GroupId
        WHERE ld.DealId = @DealId;

        IF @DealName IS NULL
        BEGIN
            SELECT @ErrCode = 1001
                 , @ErrMsg = N'Deal does not exist.';
            RETURN;
        END

        IF @StatusId NOT IN (0, 1, 2)
        BEGIN
            SELECT @ErrCode = 1002
                 , @ErrMsg = N'Invalid Status ID.';
            RETURN;
        END
    END

    -- Old data for writing log
    SELECT @OldData = (
        SELECT ld.DealId AS 'di'
              ,cg.GroupName AS 'dn'
              ,ld.StatusId AS 'st'
        FROM dbo.LandingPage_Deal ld WITH (NOLOCK)
        INNER JOIN dbo.CommGroup cg WITH (NOLOCK) 
            ON ld.DealId = cg.GroupId
        WHERE ld.DealId = @DealId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    -- Get timezone
    SELECT @TimeZone = CONVERT(TINYINT, SValue)
    FROM dbo.SystemSettings WITH (NOLOCK)
    WHERE SName = 'TimeZone';

    SELECT @CurrentDate = DATEADD(HOUR, @TimeZone, GETUTCDATE());

    BEGIN TRY
        UPDATE d WITH (ROWLOCK, UPDLOCK)
        SET d.StatusId     = ISNULL(@StatusId, d.StatusId)
           ,d.UpdatedBy    = @UserId
           ,d.UpdatedDate  = @CurrentDate
        FROM dbo.LandingPage_Deal d
        WHERE d.DealId = @DealId;
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
        SELECT ld.DealId AS 'di'
              ,cg.GroupName AS 'dn'
              ,ld.StatusId AS 'st'
        FROM dbo.LandingPage_Deal ld WITH (NOLOCK)
        INNER JOIN dbo.CommGroup cg WITH (NOLOCK) 
            ON ld.DealId = cg.GroupId
        WHERE ld.DealId = @DealId
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