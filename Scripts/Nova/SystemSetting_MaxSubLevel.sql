/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20210426@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Change setting max sub level from 4 to 1000 (https://nexdev.net/issues/153465)

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/

update dbo.SystemSettings with (rowlock)
set SValue = '1000'
where SName = 'MaxSubLevel'