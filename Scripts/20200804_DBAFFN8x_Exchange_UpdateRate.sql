/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200804@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Update exchange data for 2 columns THB, IDR
*/

-- use Affiliate_N88
-- use Affiliate_N8B
-- use Affiliate_N8G

update e with (rowlock)
set e.THB = o.THB, e.IDR = o.IDR
from dbo.ExchangeOanda e
	inner join bodb02.dbo.ExchangeDailyOanda o with (nolock)
		on e.ExchangeDate = o.ExchangeDate and e.ExchangeId = o.ExchangeId
where e.THB is null or e.IDR is null
go