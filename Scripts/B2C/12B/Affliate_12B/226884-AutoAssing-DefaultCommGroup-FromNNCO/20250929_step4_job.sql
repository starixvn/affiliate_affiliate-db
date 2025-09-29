/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
    Created:      20250926@Lewis
    Task:         NNCO Affiliate Monthly Migration Process – Migrate affiliates from NNCO Default Comm Group to Default Comm Group
    DB:           DBAFF12B-Affiliate_12B
	Description:  Step 4 - Jobname: 'Affiliate_12B: Summarize Data Monthly'
*/
USE [msdb]
GO

-- Add Step 4: NNCO Auto Assign to existing job "Affiliate_12B: Summarize Data Monthly"
DECLARE @jobId BINARY(16)
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

-- Get the job ID
SELECT @jobId = job_id 
FROM msdb.dbo.sysjobs 
WHERE name = N'Affiliate_12B: Summarize Data Monthly'

IF @jobId IS NOT NULL
BEGIN
    -- Add Step 4: NNCO Auto Assign
    EXEC @ReturnCode = msdb.dbo.sp_add_jobstep 
        @job_id = @jobId, 
        @step_name = N'NNCO Auto Assign DefaultCommGroup', 
        @step_id = 4, 
        @cmdexec_success_code = 0, 
        @on_success_action = 1,  -- Quit with success (last step)
        @on_success_step_id = 0, 
        @on_fail_action = 2,     -- Quit with failure
        @on_fail_step_id = 0, 
        @retry_attempts = 0, 
        @retry_interval = 0, 
        @os_run_priority = 0, 
        @subsystem = N'TSQL', 
        @command = N'IF DAY(GETDATE()) <> 1
	RETURN

DECLARE @ProcessDate DATETIME
SELECT  @ProcessDate = CONVERT(DATE, GETDATE())

-- Execute NNCO Auto Assignment for current month
EXEC dbo.Task_Aff_Deal_AutoAssign @ProcessDate = @ProcessDate', 
        @database_name = N'Affiliate_12B', 
        @flags = 0

    IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    BEGIN
        PRINT 'Error: Failed to add Step 4 - NNCO Auto Assign'
        RETURN
    END

    -- Update Step 3 to continue to Step 4 instead of quit
    EXEC @ReturnCode = msdb.dbo.sp_update_jobstep 
        @job_id = @jobId,
        @step_id = 3,
        @on_success_action = 3,  -- Go to next step
        @on_success_step_id = 0

    IF (@@ERROR <> 0 OR @ReturnCode <> 0) 
    BEGIN
        PRINT 'Error: Failed to update Step 3 success action'
        RETURN
    END

    PRINT 'SUCCESS: Added Step 4 - NNCO Auto Assign to job "Affiliate_12B: Summarize Data Monthly"'
END
ELSE
BEGIN
    PRINT 'ERROR: Job "Affiliate_12B: Summarize Data Monthly" not found'
END
GO