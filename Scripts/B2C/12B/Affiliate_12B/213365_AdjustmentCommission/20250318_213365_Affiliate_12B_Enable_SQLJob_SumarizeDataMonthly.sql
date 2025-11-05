/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250318@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Enable job Calulate Commission on 12Bet V2 [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12B: Summarize Data Monthly', @enabled = 1
GO