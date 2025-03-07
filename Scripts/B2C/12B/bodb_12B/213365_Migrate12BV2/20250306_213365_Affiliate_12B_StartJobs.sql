/*<info serverAlias="DB12B-bodb_12B,DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250305@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: start job [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_start_job @job_name = 'Affiliate_12B: Generate Data Daily';