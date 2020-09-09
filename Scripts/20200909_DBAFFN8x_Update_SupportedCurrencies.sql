/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200909@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Update supported currencies
*/

-- use Affiliate_N88

-- use Affiliate_N8B

-- use Affiliate_N8G

if DB_NAME() = 'Affiliate_N88'
begin
	update dbo.SystemSettings with (rowlock)
	set SValue = '2:MYR,4:THB,13:CNY,15:IDR'
	where SName = 'AFF_SupportedCurrencies'

	update dbo.MediaGallery with (rowlock)
	set Currencies = 'MYR,THB,CNY,IDR'
	where MediaId BETWEEN 1 AND 60
		and TargetId = 1
end
else
begin
	update dbo.SystemSettings with (rowlock)
	set SValue = '51:VND'
	where SName = 'AFF_SupportedCurrencies'

	update dbo.MediaGallery with (rowlock)
	set Currencies = 'VND'
	where TargetId = 1
end