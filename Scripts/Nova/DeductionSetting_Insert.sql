/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20210205@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Missing Platform Fee Setting (DeductionId = 10)

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/

-- Note: restart job "Affiliate_N88: Summarize Data Monthly" after run script

declare @DeductionSetting table (GroupId int, ProductId int, GroupProductId int, DeductedPercentage decimal (9, 8), DeductedAmount money, IsDeductedPercent bit)
insert into @DeductionSetting (GroupId, ProductId)
select c.GroupId, p.ProductId
from dbo.Products p with (nolock)
	cross join dbo.CommGroup c with (nolock)

delete t
from @DeductionSetting t
	inner join dbo.DeductionSetting ds with (nolock)
		on t.GroupId = ds.GroupId and t.ProductId = ds.ProductId and ds.DeductionId = 10

update t
set t.GroupProductId = ds.GroupProductId
	,t.DeductedPercentage = ds.DeductedPercentage
	,t.DeductedAmount = ds.DeductedAmount
	,t.IsDeductedPercent = ds.IsDeductedPercent
from @DeductionSetting t
	inner join dbo.DeductionSetting ds with (nolock)
		on t.GroupId = ds.GroupId and t.ProductId = 1 and ds.DeductionId = 10

insert into dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
select GroupId, 10 as DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent
from @DeductionSetting

insert into dbo.DeductionSettingHistory(GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
select GroupId, '2021-01-31' as MonthDate, 10 as DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent
from @DeductionSetting