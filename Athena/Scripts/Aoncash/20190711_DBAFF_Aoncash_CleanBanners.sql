use Affiliate_Aoncash
go

/*
	Created: 20190711@Percy
	DB: DBAFF.Affiliate_Aoncash
	Task: Clean all old banners for rebuild Aoncash AFF site [RedmineID: #116108]
*/

delete from dbo.Banners with (rowlock, updlock)
go