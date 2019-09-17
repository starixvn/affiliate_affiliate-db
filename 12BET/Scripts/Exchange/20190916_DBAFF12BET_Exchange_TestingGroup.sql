use Affiliate_12BET
go

/*
	Created: 20190916@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Initialize data for testing
*/

-- PlatFormFee for Exchange
insert into dbo.DeductionSetting (GroupID, DeductionID, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
select GroupId, 10 AS DeductionId, 0 AS DeductedPercentage, 0 AS NextDeductedPercentage, 19 AS ProductId, 1 AS GroupProductId, 1 AS NextGroupProductId
from dbo.CommGroup cg with (nolock)

insert into dbo.DeductionSettingHistory(GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId, GroupProductId)
select GroupId, '2019-09-30' AS MonthDate, 10 AS DeductionId, 0 AS DeductedPercentage, 19 AS ProductId, 1 AS GroupProductId
from dbo.CommGroup cg with (nolock)



-- Setting for jobs
insert into dbo.APIProductSettings (ProductId, SettingName, SettingValue)
select 9, '3rdProductId', '10' union all
select 9, 'SourceTable', '3rdProducts' union all
select 19, '3rdProductId', '31' union all
select 19, 'LastQueueId', '457087' union all
select 19, 'LaunchDate', '2019-09-01' union all
select 19, 'SourceTable', '3rdProducts'


-- Testing group
update dbo.DeductionSetting with (rowlock)
set DeductedPercentage = 0.15, NextDeductedPercentage = 0.15
where ProductId = 19 AND DeductionID = 10 -- PlatFormFee
	and GroupID = 145 -- CGTest1

update dbo.DeductionSetting with (rowlock)
set DeductedPercentage = 0.3, NextDeductedPercentage = 0.3
where ProductId = 19 AND DeductionID = 13 -- Exchange WL Share
	and GroupID = 145 -- CGTest1

update dbo.DeductionSetting with (rowlock)
set DeductedPercentage = 0.4, NextDeductedPercentage = 0.4
where ProductId = 19 AND DeductionID = 14 -- Exchange Comm Share
	and GroupID = 145 -- CGTest1


update dbo.DeductionSettingHistory with (rowlock)
set DeductedPercentage = 0.15
where ProductId = 19 AND DeductionID = 10 -- PlatFormFee
	and GroupID = 145 -- CGTest1
	and MonthDate = '2019-09-30'

update dbo.DeductionSettingHistory with (rowlock)
set DeductedPercentage = 0.3
where ProductId = 19 AND DeductionID = 13 -- Exchange WL Share
	and GroupID = 145 -- CGTest1
	and MonthDate = '2019-09-30'

update dbo.DeductionSettingHistory with (rowlock)
set DeductedPercentage = 0.4
where ProductId = 19 AND DeductionID = 14 -- Exchange Comm Share
	and GroupID = 145 -- CGTest1
	and MonthDate = '2019-09-30'