use msdb
go

/*
	Created: 20191209@Percy
	DB: DBAFF12BET
	Task:
		1. Merge monthly jobs to 1 job
		2. Merge daily jobs to 1 job
*/

-- 1. Monthly jobs:
/*
	- Affiliate_12BET: Calculate Commission Monthly
	- Affiliate_12BET: Archive Setting Monthly
*/

-- remove 1 job
exec sp_update_job
	@job_name = 'Affiliate_12BET: Calculate Commission Monthly'
	,@enabled = 0

exec sp_delete_job
	@job_name = 'Affiliate_12BET: Calculate Commission Monthly'
	,@delete_unused_schedule=1

-- update remain job
exec sp_update_job
	@job_name = 'Affiliate_12BET: Archive Setting Monthly'
	,@new_name = 'Affiliate_12BET: Summarize Data Monthly'

exec sp_update_jobschedule
	@job_name = 'Affiliate_12BET: Summarize Data Monthly'
	,@name=N'Monthly'
	,@new_name = '1st Monthly'

exec sp_add_jobschedule
	@job_name = 'Affiliate_12BET: Summarize Data Monthly'
	,@name = N'5th Monthly'
	,@enabled = 1
	,@freq_type = 16
	,@freq_interval = 5
	,@freq_subday_type = 1
	,@freq_subday_interval = 0
	,@freq_relative_interval = 0
	,@freq_recurrence_factor = 1
	,@active_start_date = 20180817
	,@active_end_date = 99991231
	,@active_start_time = 0
	,@active_end_time = 235959

exec sp_add_jobstep
	@job_name = 'Affiliate_12BET: Summarize Data Monthly'
	,@step_name = N'Calculate Commission'
	,@step_id = 3
	,@cmdexec_success_code = 0
	,@on_success_action = 1
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem = N'TSQL'
	,@command = N'IF DAY(GETDATE()) <> 5
	RETURN

DECLARE @MonthDate SMALLDATETIME
SELECT  @MonthDate = DATEADD(MONTH, -1, CONVERT(DATE, GETDATE()))

EXEC dbo.Task_Aff_Monthly_Commission @MonthDate = @MonthDate'
	,@database_name=N'Affiliate_12BET'
	,@flags=0

exec sp_update_jobstep
	@job_name = 'Affiliate_12BET: Summarize Data Monthly'
	,@step_id = 1
	,@command = N'IF DAY(GETDATE()) <> 1
	RETURN

DECLARE @MonthDate SMALLDATETIME
SELECT  @MonthDate = DATEADD(MONTH, -1, CONVERT(DATE, GETDATE()))

EXEC dbo.Task_Aff_ClickStatistics_Archive @MonthDate = @MonthDate'

exec sp_update_jobstep
	@job_name = 'Affiliate_12BET: Summarize Data Monthly'
	,@step_id = 2
	,@on_success_action = 3
	,@command = N'IF DAY(GETDATE()) <> 1
	RETURN

DECLARE @MonthDate SMALLDATETIME
SELECT  @MonthDate = DATEADD(MONTH, -1, CONVERT(DATE, GETDATE()))

EXEC dbo.Task_Aff_Settings_Archive @MonthDate = @MonthDate'


-- 2. Daily jobs:
/*
	- Affiliate_12BET: Generate Data Daily (keep and merge with 4 jobs below)
	- Affiliate_12BET: Generate Queue Data
	- Affiliate_12BET: Generate Data API Daily
	- Affiliate_12BET: Check and Correct Member Data Daily
	- Affiliate_12BET-Import member signup

Remove unused jobs:
	Affiliate - Click Statistics Summary
	Affiliate - Monthly Transfer
	Affiliate_12BET_Check_Consistency_Data
*/

-- remove 7 jobs
exec sp_update_job
	@job_name = 'Affiliate_12BET: Generate Queue Data'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate_12BET: Generate Data API Daily'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate_12BET: Check and Correct Member Data Daily'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate_12BET-Import member signup'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate - Click Statistics Summary'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate - Monthly Transfer'
	,@enabled = 0

exec sp_update_job
	@job_name = 'Affiliate_12BET_Check_Consistency_Data'
	,@enabled = 0
--------------------------------------------------------
exec sp_delete_job
	@job_name = 'Affiliate_12BET: Generate Queue Data'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate_12BET: Generate Data API Daily'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate_12BET: Check and Correct Member Data Daily'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate_12BET-Import member signup'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate - Click Statistics Summary'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate - Monthly Transfer'
	,@delete_unused_schedule = 1

exec sp_delete_job
	@job_name = 'Affiliate_12BET_Check_Consistency_Data'
	,@delete_unused_schedule = 1

-- update remain job
exec sp_update_jobstep
	@job_name = 'Affiliate_12BET: Generate Data Daily'
	,@step_id = 1
	,@command = N'EXEC dbo.Task_Aff_Member_Ins
	
EXEC dbo.Task_Aff_ImportMemberSignUp'

exec sp_add_jobstep
	@job_name = 'Affiliate_12BET: Generate Data Daily'
	,@step_name = 'Parse XML Data'
	,@step_id = 2
	,@cmdexec_success_code = 0
	,@on_success_action = 3
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 3
	,@retry_interval = 1
	,@os_run_priority = 0
	,@subsystem = N'TSQL'
	,@command = N'EXEC dbo.Task_APIProduct_ImportQueue_Process_Job'
	,@database_name = N'Affiliate_12BET'
	,@flags = 0

exec sp_add_jobstep
	@job_name = 'Affiliate_12BET: Generate Data Daily'
	,@step_name = 'Check and Correct Member Data'
	,@step_id = 4
	,@cmdexec_success_code = 0
	,@on_success_action = 1
	,@on_success_step_id = 0
	,@on_fail_action = 2
	,@on_fail_step_id = 0
	,@retry_attempts = 0
	,@retry_interval = 0
	,@os_run_priority = 0
	,@subsystem = N'TSQL'
	,@command = N'EXEC dbo.Task_Aff_ImportData_CheckData_Job
	
EXEC dbo.Task_Aff_ImportData_API_CheckData_Job'
	,@database_name = N'Affiliate_12BET'
	,@flags = 0

exec sp_update_jobstep
	@job_name = 'Affiliate_12BET: Generate Data Daily'
	,@step_id = 3
	,@on_success_action = 3
	,@command = N'EXEC dbo.Task_Aff_ImportData_Job
	
EXEC dbo.Task_Aff_ImportData_API_Job'
