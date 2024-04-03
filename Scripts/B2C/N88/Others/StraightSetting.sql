/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20210715@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: New structure for P2P Revenue

	use Affiliate_N88
	use Affiliate_N8B
	use Affiliate_N8G
*/

-- I. New columns/tables
alter table dbo.rptMemberDaily
	add Revenue money
go

alter table dbo.rptAffCommission
	add Revenue money
		,P2PFee	money
		,PlatFormFee money
		,OperationalFee	money
		,DepositFee	money
		,WithdrawalFee money
go

create table dbo.rptAffMonthly
(
	MonthDate smalldatetime
	,AffId int
	,GroupId int
	,ProductId int
	,Turnover money
	,Winloss money
	,Revenue money
	constraint PK_rptAffMonthly primary key clustered
	(
		MonthDate asc
		,AffId asc
		,GroupId asc
		,ProductId asc
	)
) on ReportData
go

create table dbo.StraightSetting
(
	GroupId int
	,ProductId int
	,GroupProductId int 
	,DeductedPercentage decimal(9, 8)
	,Commission decimal(9, 8)
	,constraint PK_StraightSetting primary key clustered
	(
		GroupId asc
		,ProductId asc
	)
) on SettingData
go

create table dbo.StraightSettingHistory
(
	GroupId int
	,MonthDate datetime
	,ProductId int
	,GroupProductId int 
	,DeductedPercentage decimal(9, 8)
	,Commission decimal(9, 8)
	,constraint PK_StraightSettingHistory primary key nonclustered
	(
		GroupId asc
		,MonthDate asc
		,ProductId asc
	)
) on SettingData
go

create clustered index CIX_StraightSettingHistory on dbo.StraightSettingHistory (MonthDate, GroupId) on SettingData
go

alter table dbo.Deductions
	add Commission decimal(9,8) constraint DF_Deductions_Commission default (0)
go

alter table dbo.Products
	add IsP2P bit constraint DF_Products_IsP2P default (0)
go

-- II. Initialize data

insert into dbo.SystemSettings (SName, SValue)
values ('P2P_CutOffDate', '2021-07-01')
go

update dbo.Products set IsP2P = case when ProductId in (41, 42) then 1 else 0 end
go

update dbo.Deductions with (rowlock) set Commission = 0
go

insert into dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsDeductedPercent, Commission)
values (15, 'P2P Fee', 0.1, 1, 0.3)
go

insert into dbo.StraightSetting (GroupId, ProductId, GroupProductId, DeductedPercentage, Commission)
select GroupId, ProductId, 1 as GroupProductId, 0.1 as DeductedPercentage, 0.3 as Commission
from (select GroupId from dbo.CommGroup with (nolock) where IsDeleted = 0) g
	cross join (select ProductId from dbo.Products with (nolock) where IsP2P = 1) p
go

insert into dbo.StraightSettingHistory (GroupId, MonthDate, ProductId, GroupProductId, DeductedPercentage, Commission)
select GroupId, '2021-07-31' as MonthDate, ProductId, GroupProductId, DeductedPercentage, Commission from StraightSetting with (nolock)
go

-------
declare @CommGroup table (GroupId int, GroupProductId int)
insert into @CommGroup (GroupId)
select GroupId from dbo.CommGroup with (nolock) where IsDeleted = 0

delete cg
from @CommGroup cg
where exists (select 1 from dbo.DeductionSetting ds with (nolock) where ds.GroupId = cg.GroupId and ds.DeductionId = 10 and ds.ProductId = 47)

update cg
set cg.GroupProductId = s.GroupProductId
from @CommGroup cg
	cross apply (
		select top 1 ds.GroupProductId
		from dbo.DeductionSetting ds with (nolock) where ds.GroupId = cg.GroupId and ds.DeductionId = 10
			and DeductedPercentage = 0.1
	) s

insert into dbo.DeductionSetting (GroupId, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
select GroupId, 10 as DeductionId, 47 as ProductId, GroupProductId, 0.1 as DeductedPercentage, 0 as DeductedAmount, 1 as IsDeductedPercent from @CommGroup

insert into dbo.DeductionSettingHistory (GroupId, MonthDate, DeductionId, ProductId, GroupProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
select GroupId, '2021-07-31' as MonthDate, 10 as DeductionId, 47 as ProductId, GroupProductId, 0.1 as DeductedPercentage, 0 as DeductedAmount, 1 as IsDeductedPercent from @CommGroup
go

-- III. Migrate data
insert into dbo.rptAffMonthly (MonthDate, AffId, GroupId, ProductId, Turnover, Winloss, Revenue)
select MonthDate, AffId, GroupId, ProductId, Turnover, Winloss, 0 as Revenue from dbo.rptAffCommission with (nolock) where ProductId > 0
go

delete dbo.rptAffCommission with (rowlock, updlock) where ProductId > 0
go

update c
set c.Revenue = 0
	,c.P2PFee = 0
	,c.PlatFormFee = d.PlatFormFee
	,c.OperationalFee = d.OperationalFee
	,c.DepositFee = d.DepositFee
	,c.WithdrawalFee = d.WithdrawalFee
from dbo.rptAffCommission c
	inner join (
		select MonthDate, AffId, GroupId
			,sum(abs(PlatFormFee))	as PlatFormFee
			,sum(OperationalFee)	as OperationalFee
			,sum(DepositFee)		as DepositFee
			,sum(WithdrawalFee)		as WithdrawalFee
		from (
			select MonthDate, AffId, GroupId, GroupProductId
				,sum(case when ad.DeductionId = 10 then ad.Amount else 0 end) as PlatFormFee
				,sum(case when ad.DeductionId = 11 then ad.Amount else 0 end) as OperationalFee
				,sum(case when ad.DeductionId = 13 then ad.Amount else 0 end) as DepositFee
				,sum(case when ad.DeductionId = 14 then ad.Amount else 0 end) as WithdrawalFee
			from dbo.rptAffDeduction ad with (nolock)
			group by MonthDate, AffId, GroupId, GroupProductId
		) t
		group by MonthDate, AffId, GroupId
	) d on c.MonthDate = d.MonthDate and c.AffId = d.AffId and c.GroupId = d.GroupId
go