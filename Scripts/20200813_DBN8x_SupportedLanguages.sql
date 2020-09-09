/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/
/*
	Created: 20200813@Percy
	DB:
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Change offer language (market): EN vs VN only
*/

-- use Affiliate_N8B
-- use Affiliate_N8G

update dbo.AffDetail with (rowlock)
set PreferredLanguage = 'vi-VN'
where PreferredLanguage NOT IN ('vi-VN', 'en-US')

update dbo.DomainControl with (rowlock)
set MarketId = 'vi-VN'
where MarketId NOT IN ('vi-VN', 'en-US')

update dbo.MediaGallery with (rowlock)
set Language = 'Vietnamese'
where Language NOT IN ('Vietnamese', 'English')