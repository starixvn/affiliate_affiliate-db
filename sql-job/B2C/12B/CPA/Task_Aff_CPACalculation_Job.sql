/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_CPACalculation_Job]
    @Step INT = 0,
    @Date DATE = NULL
AS
/*
    Created: 20250805@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Job - CPA Calculation Job Wrapper

    Revisions:
        - 20250805@Sophia: Initialize SP [Redmine: # 230662]
        - 20250930@Lewis: Add step 5 6 [RedmineID: #235601]
*/
BEGIN
    SET NOCOUNT ON;
    DECLARE @StartTime DATETIME, @EndTime DATETIME, @Status NVARCHAR(20);
    DECLARE @ErrCode INT, @ErrMsg NVARCHAR(4000);

    -- Step 0: Main SP - Define @CPADate = yesterday
    --   (Set @Date to yesterday in GMT+8 if not provided)
    IF @Date IS NULL
        SET @Date = CONVERT(DATE, DATEADD(HOUR, 8, GETUTCDATE()) - 1);

        IF @Step IN (0, 1)
        BEGIN
            -- Step 1: Reset IsAbnormal player - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAResetIsAbnormal @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAResetIsAbnormal', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Reset IsAbnormal.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Reset IsAbnormal.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 2)
        BEGIN
            -- Step 2: Active Period - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAActivePeriod @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAActivePeriod', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Active Period.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Active Period.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 3)
        BEGIN
            -- Step 3: Holding Period - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAHoldingPeriod @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAHoldingPeriod', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Holding Period.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Holding Period.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 4)
        BEGIN
            -- Step 4: Mark IsAbnormal player - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAMarkIsAbnormal @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAMarkIsAbnormal', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Mark IsAbnormal.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Mark IsAbnormal.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 5)
        BEGIN
            -- Step 5: Check Redeposit Status - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPACheckRedeposit @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPACheckRedeposit', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Check Redeposit.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Check Redeposit.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 6)
        BEGIN
            -- Step 6: Aff Payment Schedule - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAPaymentSchedule @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;

            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAPaymentSchedule', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN '' ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Payment Schedule.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Payment Schedule.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 7)
        BEGIN
            -- Step 7: Approval Period - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg ='';

            EXEC dbo.Task_Aff_CPAApprovalPeriod @CPADate = @Date, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_CPAApprovalPeriod', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN '' ELSE ISNULL(@ErrMsg, 'Unknown error occurred during CPA Approval Period.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during CPA Approval Period.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END

        IF @Step IN (0, 8)
        BEGIN
            -- Step 8: Update Deal Schedule - Nested SP
            SET @StartTime = SYSDATETIME();
            SET @ErrCode = 0; SET @ErrMsg = NULL;

            EXEC dbo.Task_Aff_UpdateDealSchedule @Date = @Date, @Type = 'CPA', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT;
           
            SET @EndTime = SYSDATETIME();
            SET @Status = CASE WHEN @ErrCode = 0 THEN N'Success' ELSE N'Failed' END;

            INSERT INTO CPAJobLog (StepName, ExecDate, StartTime, EndTime, Status, ErrorMessage)
            VALUES ('Task_Aff_UpdateDealSchedule', @Date, @StartTime, @EndTime, @Status, CASE WHEN @ErrCode = 0 THEN NULL ELSE ISNULL(@ErrMsg, 'Unknown error occurred during Update Deal Schedule.') END);
           
            IF @ErrCode > 0
            BEGIN
                SET @ErrMsg = ISNULL(@ErrMsg, 'Unknown error occurred during Update Deal Schedule.');
                RAISERROR(@ErrMsg, 16, 1);
            END
        END
   
    -- Keep only the latest 2000 rows in CPAJobLog, delete older rows (by LogID)
    DECLARE @MaxID INT = 0;
    SELECT @MaxID = MAX(LogID) FROM CPAJobLog;
    
    DELETE FROM CPAJobLog WITH (ROWLOCK, UPDLOCK) 
    WHERE LogID < (@MaxID - 2000);
END;
GO
