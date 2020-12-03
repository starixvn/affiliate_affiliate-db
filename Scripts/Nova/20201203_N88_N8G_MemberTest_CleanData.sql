/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20201203@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8G-Affiliate_N8G
	Task: Clean up test member due to testing on member site

	use Affiliate_N88
	go
	use Affiliate_N8G
	go
*/

-- Affiliate_N88: 17 rows
-- Affiliate_N8G: 301 rows
delete mi with (rowlock, updlock)
from dbo.MemberInfo mi
	left join dbo.AffInfo ai with (nolock) on mi.AffId = ai.AffId
where ai.AffId is null

-- Affiliate_N88: 32 rows
-- Affiliate_N8G: 419 rows
delete mi with (rowlock, updlock)
from dbo.rptMemberDaily mi
	left join dbo.AffInfo ai with (nolock) on mi.AffId = ai.AffId
where ai.AffId is null