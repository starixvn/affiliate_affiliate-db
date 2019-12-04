use msdb
go

/*
	Created: 20191204@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Reschedule commission monthly from 8th to 5th
*/

exec msdb.dbo.sp_update_jobschedule
	@job_name='Affiliate_12BET: Calculate Commission Monthly',
	@name=N'Monthly',
	@freq_interval=5