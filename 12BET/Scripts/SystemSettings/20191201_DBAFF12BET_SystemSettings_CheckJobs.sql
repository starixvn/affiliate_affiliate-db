use Affiliate_12BET
go

/*
	Created: 20191201@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add setting for check data job - check 1 time per day
*/

declare @SValue varchar(200) = convert(varchar(10), getdate() - 1, 120)

insert into dbo.SystemSettings (SName, SValue)
select 'AFF_CheckData_Bettrans', @SValue
union all
select 'AFF_CheckData_API', @SValue