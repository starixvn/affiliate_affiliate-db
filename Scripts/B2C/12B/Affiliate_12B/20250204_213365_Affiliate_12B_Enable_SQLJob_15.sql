/*<info serverAlias="DB12B-bodb_12B,DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250204@Eddie
	DB: DB12B-bodb_12B, DBAFF12B-Affiliate_12B
	Task: Enable job [RedmineID: #212201]
*/
USE [msdb]
GO

-- bodb_12B
EXEC msdb.dbo.sp_update_job @job_name = N'bodb_12B: Generate daily data', @enabled = 1
GO

EXEC msdb.dbo.sp_update_job @job_name = N'bodb_12B: Archive data', @enabled = 1
GO

EXEC msdb.dbo.sp_update_job @job_name = N'bodb_12B: API_Queue Process', @enabled = 1
GO

-- Affiliate_12B
EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12B: Generate Data Daily', @enabled = 1
GO

EXEC msdb.dbo.sp_update_job @job_name = N'Affiliate_12B: Summarize Data Monthly', @enabled = 1
GO