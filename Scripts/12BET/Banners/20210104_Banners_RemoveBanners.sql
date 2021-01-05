/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20210104@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Remove banners under 'Republic of India' market

	
*/

use Affiliate_12BET
go

delete dbo.Banners with (rowlock, updlock)
where Language = 'Republic of India'