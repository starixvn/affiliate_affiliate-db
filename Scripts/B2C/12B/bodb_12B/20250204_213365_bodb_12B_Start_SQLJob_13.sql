/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250204@Eddie
	DB: DB12B-bodb_12B
	Task: start job [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_start_job @job_name = N'bodb_12B: API_Queue Process'
GO