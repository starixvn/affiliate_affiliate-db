/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20251103@Lewis.Cao
    DB: DBAFF12B-Affiliate_12B
    Task: Modify SQL Job - Add Approval Period and Update Next Schedule Billing steps
    RedmineID: #242839
    
    Purpose: Modify the "Affiliate_12B: CPA Calculation Daily Job" to add new steps and reorder existing ones
    Business Context: 
    - Add Step 7: Approval Period (EXEC dbo.Task_Aff_CPACalculation_Job @Step=7)
    - Add Step 8: Update Next Schedule Billing (EXEC dbo.Task_Aff_CPACalculation_Job @Step=8)
    - Rename Step 5 to "Check Redeposit Status"
    - Rename Step 6 to "Payment Schedule Affiliate" 
    - Move Archive Landing Page Preview Data step to the end
*/

USE msdb
GO

DECLARE @job_id UNIQUEIDENTIFIER
SELECT @job_id = job_id FROM dbo.sysjobs WHERE name = 'Affiliate_12B: CPA Calculation Daily Job'

IF @job_id IS NULL
BEGIN
    RAISERROR('Job "Affiliate_12B: CPA Calculation Daily Job" not found', 16, 1)
    RETURN
END

-- First, delete all existing steps to recreate them in correct order
EXEC dbo.sp_delete_jobstep @job_id = @job_id, @step_id = 0

-- Step 1: Reset IsAbnormal (unchanged)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 1: Reset IsAbnormal',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=1;',
    @database_name = N'Affiliate_12B'


-- Step 2: Active Period (unchanged)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 2: Active Period',
    @step_id = 2,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=2;',
    @database_name = N'Affiliate_12B'


-- Step 3: Holding Period (unchanged)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 3: Holding Period',
    @step_id = 3,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=3;',
    @database_name = N'Affiliate_12B'


-- Step 4: Mark IsAbnormal (unchanged)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 4: Mark IsAbnormal',
    @step_id = 4,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=4;',
    @database_name = N'Affiliate_12B'


-- Step 5: Check Redeposit Status (renamed from original Step 5)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 5: Check Redeposit Status',
    @step_id = 5,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=5;',
    @database_name = N'Affiliate_12B'


-- Step 6: Payment Schedule Affiliate (renamed from original Step 6)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 6: Payment Schedule Affiliate',
    @step_id = 6,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=6;',
    @database_name = N'Affiliate_12B'


-- Step 7: Approval Period (NEW)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 7: Approval Period',
    @step_id = 7,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=7;',
    @database_name = N'Affiliate_12B'


-- Step 8: Update Next Schedule Billing (NEW)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step 8: Update Next Schedule Billing',
    @step_id = 8,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.Task_Aff_CPACalculation_Job @Step=8;',
    @database_name = N'Affiliate_12B'


-- Step 9: Archive Landing Page Preview Data (moved to end)
EXEC dbo.sp_add_jobstep
    @job_id = @job_id,
    @step_name = N'Step: Archive Landing Page Preview Data',
    @step_id = 9,
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'EXEC [dbo].[Task_Aff_LandingPagePreview_Archive];',
    @database_name = N'Affiliate_12B'


-- Verification query
SELECT 
    j.name AS job_name,
    js.step_id,
    js.step_name,
    js.command,
    js.on_success_action,
    js.on_fail_action
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
WHERE j.name = 'Affiliate_12B: CPA Calculation Daily Job'
ORDER BY js.step_id ASC;