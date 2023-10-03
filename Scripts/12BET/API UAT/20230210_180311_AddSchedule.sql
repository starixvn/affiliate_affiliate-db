/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20230310@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: add Schedule

	
*/

USE [msdb]
GO

DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_Name=N'Affiliate_12BET: ImportData_UAT', @name=N'30 minute(s)', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20230310, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
GO