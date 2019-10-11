use Affiliate_12BET
go

/*
	Created: 20190919@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Exchange - Set release date from 01 Oct 2019 + Clean testing data
*/

-- 1 row
update dbo.APIProductSettings with (rowlock)
set SettingValue = '2019-10-01'
where ProductId = 19 and SettingName = 'LaunchDate'

-- 752 rows
delete dbo.rptMemberDaily with (rowlock, updlock)
where ProductId = 19 and WinlostDate >= '2019-09-01'