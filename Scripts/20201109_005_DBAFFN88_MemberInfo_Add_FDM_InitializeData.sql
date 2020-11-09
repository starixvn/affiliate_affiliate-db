/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20201109@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Add new column: FirstDepositDate, FirstDepositAmount to get FDM value
*/


-- 24 rows
update mi with (rowlock, updlock)
set mi.FirstDepositDate = dateadd(hour, 8, d.CreateTime)
	,mi.FirstDepositAmount = d.Amount
from Affiliate_N88.dbo.MemberInfo mi
	inner join bodb_N88.dbo.DepositInfo d with (nolock) on mi.CustId = d.CustId
where d.FirstDeposit = 1
	and d.SiteId = 1

-- 0 row
update mi with (rowlock, updlock)
set mi.FirstDepositDate = dateadd(hour, 8, d.CreateTime)
	,mi.FirstDepositAmount = d.Amount
from Affiliate_N8B.dbo.MemberInfo mi
	inner join bodb_N88.dbo.DepositInfo d with (nolock) on mi.CustId = d.CustId
where d.FirstDeposit = 1
	and d.SiteId = 3

-- 11 rows
update mi with (rowlock, updlock)
set mi.FirstDepositDate = dateadd(hour, 8, d.CreateTime)
	,mi.FirstDepositAmount = d.Amount
from Affiliate_N8G.dbo.MemberInfo mi
	inner join bodb_N88.dbo.DepositInfo d with (nolock) on mi.CustId = d.CustId
where d.FirstDeposit = 1
	and d.SiteId = 2