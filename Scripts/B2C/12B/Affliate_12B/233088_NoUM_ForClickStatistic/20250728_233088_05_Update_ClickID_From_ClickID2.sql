/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Update ClickStatistics.ClickId with ClickID2 where ClickID2 > ClickId [RedmineID: #233088]
*/

SET NOCOUNT ON;

-- Delete rows where ClickID2 > ClickId, but keep the data for re-insert

SELECT *
INTO #ToReinsert
FROM ClickStatistics WITH (NOLOCK)
WHERE ClickID2 > ClickId;

DELETE c
FROM ClickStatistics c WITH (ROWLOCK, UPDLOCK)
WHERE c.ClickID2 > c.ClickId;

SET IDENTITY_INSERT ClickStatistics ON;

INSERT INTO ClickStatistics (
    ClickId, AffId, UpdatedTime, IP, Date, Browser, URLReferrer, DomainReferrer, OS, Device,
    BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent, Country, LanguageCode,
    SportCode, RedirectURL, Status, DeviceType, AffMediaLink, ChannelCode, ClickID2
)
SELECT
    ClickID2, AffId, UpdatedTime, IP, Date, Browser, URLReferrer, DomainReferrer, OS, Device,
    BrowserVersion, BrowserResolution, BrowserLanguage, UserAgent, Country, LanguageCode,
    SportCode, RedirectURL, Status, DeviceType, AffMediaLink, ChannelCode, ClickID2
FROM #ToReinsert;

SET IDENTITY_INSERT ClickStatistics OFF;

DROP TABLE #ToReinsert;
