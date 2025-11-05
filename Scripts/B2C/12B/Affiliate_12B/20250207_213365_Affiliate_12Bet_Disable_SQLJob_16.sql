/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20250207@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Disable job on 12Bet V1 [RedmineID: #212201]
*/
USE [msdb]
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12BET: Clean Data', @enabled = 0
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12BET: Generate Data Daily', @enabled = 0
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12BET: Summarize Data Monthly', @enabled = 0
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12BET: ImportData_UAT', @enabled = 0
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12BET-On_user : clear login', @enabled = 0
GO