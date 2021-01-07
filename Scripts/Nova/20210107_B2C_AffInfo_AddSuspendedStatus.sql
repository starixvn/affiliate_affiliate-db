/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	use Affiliate_N88
	go

	use Affiliate_N88
	go

	use Affiliate_N88
	go
*/

alter table dbo.AffInfo
	add IsRejected bit constraint DF_AffInfo_IsRejected default ((0))
go

update dbo.AffInfo with (rowlock)
set IsRejected = 0
where IsRejected is null
go