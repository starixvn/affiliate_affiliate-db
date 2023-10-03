/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200804@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Add column MultipliedBy to Exchange table
*/

-- use Affiliate_N88
-- use Affiliate_N8B
-- use Affiliate_N8G

alter table dbo.Exchange
	add MultipliedBy int constraint DF_Exchange_MultipliedBy default((0))
go

update e with (rowlock)
set e.MultipliedBy = ee.MultipliedBy
from dbo.Exchange e
	inner join bodb02.dbo.Exchange ee with (nolock) on e.ExchangeId = ee.exchangeid
go