/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250728@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Create ClickStatistics2 table (same as ClickStatistics, but ClickId is NOT identity) [RedmineID: #233088]
*/

CREATE TABLE ClickStatistics2 (
    -- Keys
    ClickId bigint NOT NULL, -- PK
    AffId int NOT NULL,

    -- Timestamps
    UpdatedTime datetime NOT NULL,
    Date smalldatetime NOT NULL,

    -- Network Info
    IP varchar(25) NOT NULL,
    DomainReferrer nvarchar(300) NOT NULL,
    URLReferrer nvarchar(300) NOT NULL,
    RedirectURL nvarchar(256) NULL,

    -- Device/Browser Info
    Browser nvarchar(50) NOT NULL,
    BrowserVersion nvarchar(16) NULL,
    BrowserResolution nvarchar(16) NULL,
    BrowserLanguage nvarchar(8) NULL,
    OS nvarchar(50) NULL,
    Device nvarchar(50) NULL,
    DeviceType tinyint NULL CONSTRAINT DF_ClickStatistics2_DeviceType DEFAULT 0,
    UserAgent nvarchar(256) NULL,

    -- Affiliate/Marketing Info
    AffMediaLink varchar(500) NULL,
    ChannelCode varchar(50) NULL,
    Country nvarchar(256) NULL,
    LanguageCode varchar(10) NULL,
    SportCode varchar(50) NULL,

    -- Status
    Status tinyint NULL CONSTRAINT DF_ClickStatistics2_Status DEFAULT 0
)
ON [StatIndex];
GO
ALTER TABLE ClickStatistics2 ADD CONSTRAINT PK_ClickStatistics2 PRIMARY KEY NONCLUSTERED (ClickId) ON [StatIndex];
GO
CREATE CLUSTERED INDEX CIX_ClickStatistics2_AffId_Date ON ClickStatistics2(AffId, Date) ON [StatIndex];
GO
