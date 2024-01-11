/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200910@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Support data for QC testing
*/
use Affiliate_N88
go

-- 8 rows
update dbo.rptAffDeduction with (rowlock)
set Amount = 200
where DeductionId in (13, 14)
	and GroupId = 13
	and MonthDate in ('2020-07-31', '2020-08-31')
go