/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200921@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Remove Chinese Traditional market
*/

use Affiliate_N88
go

delete dbo.Market with (rowlock, updlock)
where MarketId = 'zh-TW'