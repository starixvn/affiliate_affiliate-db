/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" isFunction="0" isNested="0"></info>*/
/*
	Created: 20250822@Sally	
	Task: Customize Target country/Language list, English for all target country
	DB: DBAFF12B-Affiliate_12B
	
	Revisions:
		- 20250822@Sally: Created [RedmineID: #234155]

	Description:
		- Inactivate en-IN, en-PH market in Market table
		- Migrate data in other tables from en-IN, en-PH to en-US

*/
USE Affiliate_12B
GO

-- ======================
-- DomainControl -- 'km-KH','zh-TW' ==> update en-US
-- ======================
--SELECT COUNT(1)
UPDATE d SET d.MarketId ='en-US'
FROM DomainControl d WITH (ROWLOCK,UPDLOCK)
WHERE MarketId IN ( 'en-IN')

-- ======================
-- MediaGallery -- Cambodian
-- ======================

-- SELECT COUNT(1)
UPDATE m SET m.Language = 'English'
FROM MediaGallery  m WITH (ROWLOCK,UPDLOCK)
WHERE Language IN ('English (India)')

-- ======================
-- AffDetail
-- ======================
-- SELECT COUNT(1)
UPDATE a SET a.PreferredLanguage = 'en-US'
FROM AffDetail a WITH (ROWLOCK,UPDLOCK)
WHERE PreferredLanguage IN ( 'en-IN')


-- =====================
-- AffMediaLInk
-- =====================
-- SELECT COUNT(1)
UPDATE a SET a.LanguageCode = 'en-US'
FROM AffMediaLink a WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ( 'en-IN')