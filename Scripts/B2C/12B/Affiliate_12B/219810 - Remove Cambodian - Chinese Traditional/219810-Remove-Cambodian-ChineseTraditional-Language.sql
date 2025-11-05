/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250214@Lewis	
	Task: Remove Cambodian & Chinese Traditional
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250214@Lewis: Created [RedmineID: #219810]

	Description: km-KH ==> Cambodian kh || zh-TW ==> Chinese Traditional ch	

		Update ==> en-US	English	English	en	English
*/

-- ======================
-- DomainControl -- 'km-KH','zh-TW' ==> update en-US
-- ======================

UPDATE d SET d.MarketId ='en-US'
FROM DomainControl d WITH (ROWLOCK,UPDLOCK)
WHERE MarketId IN ('km-KH','zh-TW')

-- ======================
-- MediaGallery -- Cambodian
-- ======================

UPDATE m SET m.Language = 'English'
FROM MediaGallery  m WITH (ROWLOCK,UPDLOCK)
WHERE Language IN ('Cambodian','Chinese Traditional')

-- ======================
-- AffDetail
-- ======================

UPDATE a SET a.PreferredLanguage = 'en-US'
FROM AffDetail a WITH (ROWLOCK,UPDLOCK)
WHERE PreferredLanguage IN ('km-KH','zh-TW')

-- =====================
-- ClickStatistics
-- =====================

UPDATE c SET c.LanguageCode ='en'
FROM ClickStatistics c  WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ('ch','kh')

UPDATE c SET c.LanguageCode ='en'
FROM ClickStatistics_bk c  WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ('ch','kh')


-- =====================
-- AffMediaLInk
-- =====================

UPDATE a SET a.LanguageCode = 'en-US'
FROM AffMediaLink a WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ('zh-TW','km-KH')