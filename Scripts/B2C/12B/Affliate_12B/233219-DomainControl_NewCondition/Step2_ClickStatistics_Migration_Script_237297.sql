/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250828@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Migration missing data clickstatistics [RedmineId : #237297]	

*/
USE Affiliate_12B
GO
-- ~2k4 rows
INSERT INTO [dbo].[ClickStatistics]
           ([ClickId]
           ,[AffId]
           ,[UpdatedTime]
           ,[Date]
           ,[IP]
           ,[DomainReferrer]
           ,[URLReferrer]
           ,[RedirectURL]
           ,[Browser]
           ,[BrowserVersion]
           ,[BrowserResolution]
           ,[BrowserLanguage]
           ,[OS]
           ,[Device]
           ,[DeviceType]
           ,[UserAgent]
           ,[AffMediaLink]
           ,[ChannelCode]
           ,[Country]
           ,[LanguageCode]
           ,[SportCode]
           ,[Status])
SELECT ClickId,
    AffId,
    UpdatedTime,
    Date,
    IP,
    DomainReferrer,
    URLReferrer,
    RedirectURL,
    Browser,
    BrowserVersion,
    BrowserResolution,
    BrowserLanguage,
    OS,
    Device,
    DeviceType,
    UserAgent,
    AffMediaLink,
    ChannelCode,
    Country,
    LanguageCode,
    SportCode,
    Status
FROM dbo.tmpClickstatistics WITH (NOLOCK)
WHERE ClickId NOT IN (SELECT ClickId FROM dbo.ClickStatistics WITH (NOLOCK))

GO
IF EXISTS( SELECT 1
FROM ClickStatistics c WITH (NOLOCK)
    LEFT JOIN tmpClickstatistics ctp WITH(NOLOCK) ON c.ClickId = ctp.ClickId
WHERE ctp.ClickId IS NULL)
BEGIN
       PRINT 'Data Migration Not Completed';
END
ELSE
BEGIN
     PRINT 'Data Migration Completed';
    DROP TABLE dbo.tmpClickstatistics
END
