/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20201109@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Add new column: FirstDepositDate, FirstDepositAmount to get FDM value
*/

/*
use Affiliate_N88

use Affiliate_N8B

use Affiliate_N8G
*/

alter table dbo.MemberInfo
	add FirstDepositDate datetime
		,FirstDepositAmount money
go