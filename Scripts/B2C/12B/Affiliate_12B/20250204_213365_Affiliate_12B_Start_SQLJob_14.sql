/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250204@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: start job [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_start_job @job_name = N'Affiliate_12B: Generate Data Daily'
GO