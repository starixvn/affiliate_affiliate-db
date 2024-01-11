/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200921@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Add new rebate column
*/

/*
	use Affiliate_N88
	use Affiliate_N8B
	use Affiliate_N8G
*/

alter table dbo.rptMemberDaily
	add Rebate money
alter table dbo.rptAffCommission
	add Rebate money
go
