/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250418@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Structure [RedmineID: #227338]
*/
USE Affiliate_12B;
GO

-- Add new column
ALTER TABLE TargetCountry ADD ShortedCode VARCHAR(20) NULL;
GO

DELETE FROM TargetCountry WHERE MarketID = 'en-GB' AND CountryCode = 'MY'

-- Initialize data
UPDATE TargetCountry SET ShortedCode = CASE
    WHEN MarketID = 'bn-BD' AND CountryCode = 'BD' THEN 'bd'
    WHEN MarketID = 'zh-CN' AND CountryCode = 'CN' THEN 'cs'
    WHEN MarketID = 'id-ID' AND CountryCode = 'ID' THEN 'id'
    WHEN MarketID = 'en-IN' AND CountryCode = 'IN' AND MarketName = 'English (India)' THEN 'hien'
    WHEN MarketID = 'te-IN' AND CountryCode = 'IN' THEN 'hitg'
    WHEN MarketID = 'ja-JP' AND CountryCode = 'JP' THEN 'jp'
    WHEN MarketID = 'ko-KR' AND CountryCode = 'KR' THEN 'ko'
    WHEN MarketID = 'en-GB' AND CountryCode = 'MY' THEN 'eneuro'
    WHEN MarketID = 'en-US' AND CountryCode = 'MY' THEN 'en'
    WHEN MarketID = 'zh-CN' AND CountryCode = 'MY' THEN 'csmy'
    WHEN MarketID = 'th-TH' AND CountryCode = 'TH' THEN 'th'
    WHEN MarketID = 'vi-VN' AND CountryCode = 'VN' THEN 'vn'
    ELSE ShortedCode
END;

-- Remove en-GB English (Europe)
UPDATE Market
SET Isdeleted = 1
WHERE MarketId='en-GB'

-- Remove en-GB English (Europe)
UPDATE a SET a.PreferredLanguage = 'en-US'
FROM AffDetail a WITH (ROWLOCK,UPDLOCK)
WHERE PreferredLanguage IN ('en-GB')

-- Remove en-GB English (Europe)
UPDATE m SET m.Language = 'English'
FROM MediaGallery  m WITH (ROWLOCK,UPDLOCK)
WHERE Language IN ('English (Europe)')

-- Remove en-GB English (Europe)
UPDATE c SET c.LanguageCode ='en'
FROM ClickStatistics c  WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ('eneuro')

-- Remove en-GB English (Europe)
UPDATE c SET c.LanguageCode ='en'
FROM ClickStatistics_bk c  WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode IN ('eneuro')

-- Remove en-GB English (Europe)
UPDATE c SET c.LanguageCode = 'en-US'
FROM AffMediaLink c  WITH (ROWLOCK,UPDLOCK)
WHERE LanguageCode = 'en-GB'