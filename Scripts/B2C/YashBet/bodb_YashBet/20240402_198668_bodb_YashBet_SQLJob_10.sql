/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240402@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		2. Delete bonusSum SQL Job DB bodb_YashBet
*/
USE [msdb]
GO
USE [msdb]
GO
/****** Object:  Step [Generate data for CustBonusSummary]    Script Date: 4/2/2024 9:29:00 AM ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'e75b6bd6-24e5-4e02-9ac3-d4ea4557ea57', @step_id=2
GO
USE [msdb]
GO
/****** Object:  Step [Update TpSystemUsername in Customer table]    Script Date: 4/2/2024 9:29:00 AM ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'e75b6bd6-24e5-4e02-9ac3-d4ea4557ea57', @step_id=3
GO
USE [msdb]
GO
/****** Object:  Step [Generate data for YashBet_SumWinloss]    Script Date: 4/2/2024 9:29:00 AM ******/
EXEC msdb.dbo.sp_delete_jobstep @job_id=N'e75b6bd6-24e5-4e02-9ac3-d4ea4557ea57', @step_id=1
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'e75b6bd6-24e5-4e02-9ac3-d4ea4557ea57', @step_name=N'Generate data for YashBet_SumWinloss', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC Task_YashBet_SumWinloss_Job', 
		@database_name=N'bodb_YashBet', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_id=N'e75b6bd6-24e5-4e02-9ac3-d4ea4557ea57', @step_name=N'Update TpSystemUsername in Customer table', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.Task_Customer_Upd', 
		@database_name=N'bodb_YashBet', 
		@flags=0
GO