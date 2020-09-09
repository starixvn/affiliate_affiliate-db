/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200909@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Split Banking Fee to Deposit & Withdrawal Fee
*/

/*
use Affiliate_N88

use Affiliate_N8B

use Affiliate_N8G
*/

update dbo.Deductions with (rowlock)
set IsDeleted = 1
where DeductionId = 12

insert into dbo.Deductions (DeductionId,DeductionName,DeductedPercentage,IsTest,IsDeleted,IsDeductedPercent)
values (13,'Deposit Fee',0.02,0,0,1)
		,(14,'Withdrawal Fee',0.02,0,0,1)
go

-- DeductionSetting
insert into dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
select GroupId,13,ProductId,GroupProductId,DeductedPercentage,CASE WHEN IsDeductedPercent = 1 THEN DeductedAmount / 2.0 ELSE DeductedAmount END,IsDeductedPercent
from dbo.DeductionSetting with (nolock)
where DeductionId = 12

insert into dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
select GroupId,14,ProductId,GroupProductId,DeductedPercentage,CASE WHEN IsDeductedPercent = 1 THEN DeductedAmount / 2.0 ELSE DeductedAmount END,IsDeductedPercent
from dbo.DeductionSetting with (nolock)
where DeductionId = 12

delete dbo.DeductionSetting with (rowlock, updlock)
where DeductionId = 12
go


-- DeductionSettingHistory
insert into dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
select GroupId,MonthDate,13,ProductId,GroupProductId,DeductedPercentage,CASE WHEN IsDeductedPercent = 1 THEN DeductedAmount / 2.0 ELSE DeductedAmount END,IsDeductedPercent
from dbo.DeductionSettingHistory with (nolock)
where DeductionId = 12

insert into dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
select GroupId,MonthDate,14,ProductId,GroupProductId,DeductedPercentage,CASE WHEN IsDeductedPercent = 1 THEN DeductedAmount / 2.0 ELSE DeductedAmount END,IsDeductedPercent
from dbo.DeductionSettingHistory with (nolock)
where DeductionId = 12

delete dbo.DeductionSettingHistory with (rowlock, updlock)
where DeductionId = 12
go

-- rptAffDeduction
insert into dbo.rptAffDeduction (MonthDate,AffId,GroupId,ProductId,GroupProductId,DeductionId,Amount)
select MonthDate,AffId,GroupId,ProductId,GroupProductId,13,Amount / 2.0
from dbo.rptAffDeduction with (nolock)
where DeductionId = 12

insert into dbo.rptAffDeduction (MonthDate,AffId,GroupId,ProductId,GroupProductId,DeductionId,Amount)
select MonthDate,AffId,GroupId,ProductId,GroupProductId,14,Amount / 2.0
from dbo.rptAffDeduction with (nolock)
where DeductionId = 12

delete dbo.rptAffDeduction with (rowlock, updlock)
where DeductionId = 12
go