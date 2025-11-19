/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Task_Aff_UpdateDealSchedule
    @Date DATE
	, @Type VARCHAR(100) = ''
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created:      20250819@Lewis
    Task:         Update CPA Billing Schedule for Next Processing Cycle
    DB:           DBAFF12B-Affiliate_12B
    
    Revisions:
        - 20250819@Lewis: Initial implementation - Extracted from Task_Aff_CPAApprovalPeriod [RedmineID: #283530]
*/
BEGIN
    SET NOCOUNT ON;
    
    -- Initialize output parameters
    SET @ErrCode = 0;
    SET @ErrMsg = '';
    
    BEGIN TRY
        -- =============================================
        -- SECTION 1: INPUT VALIDATION
        -- =============================================
        
        -- Validate required parameters
        IF @Date IS NULL 
        BEGIN
            SET @ErrCode = 100;
            SET @ErrMsg = 'Parameter @Date is required and cannot be NULL';
            RETURN;
        END

        -- System constants
        DECLARE @Todate DATETIME = '9999-12-31';
        
        -- =============================================
        -- SECTION 2: UPDATE CPA BILLING SCHEDULES
        -- =============================================
        
        -- Update billing schedules for ALL CPA groups that match the billing date
        -- This includes both eligible groups (with members) and non-eligible groups (without members)
        UPDATE s WITH (UPDLOCK, ROWLOCK)
        SET s.NextBillingDate = CASE 
									WHEN sc.IntervalType = 'MONTH' THEN 
										DATEADD(DAY, 4, EOMONTH(@Date, sc.IntervalValue - 1))
									ELSE 
										DATEADD(DAY, sc.IntervalValue, @Date)
								END
        FROM dbo.DealBillingSchedule s
        INNER JOIN dbo.Schedule sc WITH (NOLOCK) ON sc.ScheduleId = s.ScheduleId
        INNER JOIN dbo.CPAGroupSetting c WITH (NOLOCK) 
            ON s.GroupId = c.GroupId 
           AND c.ToDate = @Todate
        WHERE s.NextBillingDate = @Date
			AND s.Type = @Type;
        
        -- Store affected row count for reporting
        DECLARE @UpdatedCount INT = @@ROWCOUNT;
        
        -- Success - set return values
        SET @ErrCode = 0;
        SET @ErrMsg = 'CPA Billing Schedule updated successfully. Updated ' + CAST(@UpdatedCount AS VARCHAR(10)) + ' schedules.';
             
    END TRY
    BEGIN CATCH
        -- =============================================
        -- ERROR HANDLING
        -- =============================================
        
        -- Capture error information
        SET @ErrCode = ERROR_NUMBER();
        SET @ErrMsg = ERROR_MESSAGE();
        
    END CATCH

END;
GO
