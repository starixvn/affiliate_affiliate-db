/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250303@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Disable job Calulate Commission on 12Bet V2 [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12B: Summarize Data Monthly', @enabled = 0
GO