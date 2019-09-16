use Affiliate_12BET
go

/*
	Created: 20190809@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate Exchange Product
*/

-- Add new Product
insert into dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest)
values (19, 'Exchange', 'BX', 0, 1, 1)

-- Add new column for licensee winloss, licensee comm
alter table dbo.rptMemberDaily
	add	AWinloss money null constraint [DF_rptMemberDaily_AWinloss] default ((0)),
		AComm money null constraint [DF_rptMemberDaily_AComm] default ((0))
go

alter table dbo.rptAffCommission
	add	AWinloss money null constraint [DF_rptAffCommission_AWinloss] default ((0)),
		AComm money null constraint [DF_rptAffCommission_AComm] default ((0)),
		GrossWinloss money null constraint [DF_rptAffCommission_GrossWinloss] default ((0))

-- Add new setting rate
insert into dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted)
values	(13, 'Exchange Win Loss Share', 0, 1, 0)
		,(14, 'Exchange Commission Share', 0, 1, 0)

-- Exchange Win Loss Share
insert into dbo.DeductionSetting (GroupID, DeductionID, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
select GroupId, 13 AS DeductionId, 0 AS DeductedPercentage, 0 AS NextDeductedPercentage, 19 AS ProductId, 1 AS GroupProductId, 1 AS NextGroupProductId
from dbo.CommGroup cg with (nolock)

insert into dbo.DeductionSettingHistory(GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId, GroupProductId)
select GroupId, '2019-09-30' AS MonthDate, 13 AS DeductionId, 0 AS DeductedPercentage, 19 AS ProductId, 1 AS GroupProductId
from dbo.CommGroup cg with (nolock)

-- Exchange Commission Share
insert into dbo.DeductionSetting (GroupID, DeductionID, DeductedPercentage, NextDeductedPercentage, ProductId, GroupProductId, NextGroupProductId)
select GroupId, 14 AS DeductionId, 0 AS DeductedPercentage, 0 AS NextDeductedPercentage, 19 AS ProductId, 1 AS GroupProductId, 1 AS NextGroupProductId
from dbo.CommGroup cg with (nolock)

insert into dbo.DeductionSettingHistory(GroupID, MonthDate, DeductionID, DeductedPercentage, ProductId, GroupProductId)
select GroupId, '2019-09-30' AS MonthDate, 14 AS DeductionId, 0 AS DeductedPercentage, 19 AS ProductId, 1 AS GroupProductId
from dbo.CommGroup cg with (nolock)