/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20201005@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Correct assign group for account AAJade
*/

use Affiliate_N8G
go

update dbo.Affiliate_User with (rowlock, updlock)
set GroupId = 1003 -- MKT group
where CustId = 1000000007 -- AAJade