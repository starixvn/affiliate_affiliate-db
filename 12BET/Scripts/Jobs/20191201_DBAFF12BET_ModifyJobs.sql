use Affiliate_12BET
go

/*
	Created: 20191201@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: AFF12BET - Modify import data job
*/

-- input xml data of Playtech Casino into Queue
insert into dbo.APIProductSettings (ProductId, SettingName, SettingValue)
select 3, 'LastQueueId', '1' union all
select 3, 'LaunchDate', '2013-01-18' union all -- min Aff's CasinoJoinedDate
select 3, 'SourceTable', 'APIProduct_ImportQueue'


-- update daily job schedule (daily to every 30 mins)
exec msdb.dbo.sp_update_jobschedule
		@job_name='Affiliate_12BET: Generate Data Daily',
		@name=N'Daily',
		@new_name=N'Every 30 mins',
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_time=0, 
		@active_end_time=235959