/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250206@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		5. Get Oanda From 2008		

*/
USE [msdb]
GO

EXEC msdb.dbo.sp_start_job @job_name = N'Affiliate_12B: Generate Data Daily'
GO