
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250822@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: New Landing Page Setting [RedmineId : #236797]
        - Create new Landing Page tables (LandingPage_Module, LandingPage_MediaGallery, LandingPage_Setting, LandingPage_Deal)
        - Updated columns and datatypes per latest documentation/screenshots
*/

use Affiliate_12B
GO
-- 1. Drop & Create LandingPage_Module
IF OBJECT_ID('dbo.LandingPage_Module', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Module;
CREATE TABLE LandingPage_Module (
    ModuleId INT NOT NULL,
    ModuleName NVARCHAR(200) NOT NULL,
    ModuleType SMALLINT NOT NULL,
    Remark VARCHAR(200) NULL,
    NavigateTo INT NULL,
    IsMultipleUpload BIT NOT NULL,
    IsRequired BIT NOT NULL,
    IsUnique BIT NOT NULL,
    StatusId TINYINT NULL,
    CONSTRAINT PK_LandingPage_Module PRIMARY KEY CLUSTERED (ModuleId)
) 
ON [SettingData];

-- 2. Drop & Create LandingPage_MediaGallery
IF OBJECT_ID('dbo.LandingPage_MediaGallery', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_MediaGallery;
CREATE TABLE LandingPage_MediaGallery (
    MediaId INT IDENTITY(1,1) NOT NULL,
    MediaName VARCHAR(200) NOT NULL,
    FileName VARCHAR(200) NOT NULL,
    ModuleId INT NOT NULL,
    Dimension VARCHAR(20) NULL,
    StatusId TINYINT NULL,
    TargetCountryCode VARCHAR(50) NULL,
    MarketId VARCHAR(50) NULL,
    Creator INT NOT NULL,
    CreatedDate DATETIME NOT NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    RowVer rowversion NOT NULL,
    MediaCode VARCHAR(10) NULL,
    CONSTRAINT PK_LandingPage_MediaGallery PRIMARY KEY CLUSTERED (MediaId)
) 
ON [SettingData];

CREATE NONCLUSTERED INDEX IX_LandingPage_MediaGallery_MediaName 
ON LandingPage_MediaGallery (MediaName)
ON [SettingData];

CREATE NONCLUSTERED INDEX IX_LandingPage_MediaGallery_ModuleId 
ON LandingPage_MediaGallery (ModuleId)
ON [SettingData];

-- 2a. Create LandingPage_MediaCode
IF OBJECT_ID('dbo.LandingPage_MediaCode', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_MediaCode;
CREATE TABLE LandingPage_MediaCode (
    MediaCodeId INT IDENTITY(1,1) NOT NULL,
    MediaCode VARCHAR(10) NOT NULL,
    MediaId INT NULL,
    CONSTRAINT PK_LandingPage_MediaCode PRIMARY KEY CLUSTERED (MediaCodeId)
) 
ON [SettingData];

-- 3. Drop & Create LandingPage_Deal
IF OBJECT_ID('dbo.LandingPage_Deal', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Deal;
CREATE TABLE LandingPage_Deal (
    Id SMALLINT IDENTITY(1,1) NOT NULL,
    DealId INT NOT NULL,
    Creator INT NOT NULL,
    CreatedDate DATETIME NOT NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    StatusId TINYINT NOT NULL, -- 1: active, 0: inactive
    CONSTRAINT PK_LandingPage_Deal PRIMARY KEY NONCLUSTERED (Id)
) 
ON [SettingData];

CREATE CLUSTERED INDEX CIX_LandingPage_Deal_DealId 
ON LandingPage_Deal (DealId)
ON [SettingData];

-- 4. Drop & Create LandingPage_Builder
IF OBJECT_ID('dbo.LandingPage_Builder', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Builder;
CREATE TABLE LandingPage_Builder (
    PageId INT IDENTITY(1,1) NOT NULL,
    PageName VARCHAR(200) NOT NULL,
    PageCode VARCHAR(100) NOT NULL,
    CampaignId INT NULL,
    TargetCountryCode VARCHAR(50) NOT NULL,
    MarketId VARCHAR(50) NOT NULL,
    DealIds VARCHAR(2000) NULL,
    StatusId TINYINT NULL,
    Creator INT NOT NULL,
    CreatedDate DATETIME NOT NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    RowVer ROWVERSION NOT NULL,
    CONSTRAINT PK_LandingPage_Builder PRIMARY KEY CLUSTERED (PageId)
) 
ON [SettingData];

-- Create nonclustered index on PageCode
CREATE NONCLUSTERED INDEX IX_LandingPage_Builder_PageCode
ON LandingPage_Builder (PageCode)
ON [SettingData];
GO

-- 5. Drop & Create LandingPage_Builder_Preview
IF OBJECT_ID('dbo.LandingPage_Builder_Preview', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Builder_Preview;
CREATE TABLE LandingPage_Builder_Preview (
    PageId INT IDENTITY(1,1) NOT NULL,
    PageName VARCHAR(200) NOT NULL,
    PageCode VARCHAR(100) NOT NULL,
    CampaignId INT NULL,
    TargetCountryCode VARCHAR(50) NOT NULL,
    MarketId VARCHAR(50) NOT NULL,
    DealIds VARCHAR(2000) NULL,
    StatusId TINYINT NULL,
    Creator INT NOT NULL,
    CreatedDate DATETIME NOT NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    RowVer ROWVERSION NOT NULL,
    CONSTRAINT PK_LandingPage_Builder_Preview PRIMARY KEY CLUSTERED (PageId)
) 
ON [SettingData];
GO

-- 6. Drop & Create LandingPage_BuilderDetail
IF OBJECT_ID('dbo.LandingPage_BuilderDetail', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_BuilderDetail;
CREATE TABLE LandingPage_BuilderDetail (
    PageDetailId INT NOT NULL IDENTITY(1,1),
    PageId INT NOT NULL,
    OrderId INT NULL,
    ModuleId INT NULL,
    MediaId INT NULL,
    ExtraInfo VARCHAR(8000) NULL,
    CONSTRAINT PK_LandingPage_BuilderDetail PRIMARY KEY NONCLUSTERED (PageDetailId)
) 
ON [SettingData];

CREATE CLUSTERED INDEX CIX_LandingPage_BuilderDetail_PageId
ON LandingPage_BuilderDetail (PageId)
ON [SettingData];
GO

-- 7. Drop & Create LandingPage_BuilderDetail_Preview
IF OBJECT_ID('dbo.LandingPage_BuilderDetail_Preview', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_BuilderDetail_Preview;
CREATE TABLE LandingPage_BuilderDetail_Preview (
    PageDetailId INT NOT NULL IDENTITY(1,1),
    PageId INT NOT NULL,
    OrderId INT NULL,
    ModuleId INT NULL,
    MediaId INT NULL,
    ExtraInfo VARCHAR(8000) NULL,
    CONSTRAINT PK_LandingPage_BuilderDetail_Preview PRIMARY KEY NONCLUSTERED (PageDetailId)
) 
ON [SettingData];

CREATE CLUSTERED INDEX CIX_LandingPage_BuilderDetail_Preview_PageId
ON LandingPage_BuilderDetail_Preview (PageId)
ON [SettingData];
GO

-- 8. Drop & Create LandingPage_Campaign
IF OBJECT_ID('dbo.LandingPage_Campaign', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Campaign;
CREATE TABLE LandingPage_Campaign (
    CampaignId INT NOT NULL IDENTITY(1000,1),
    CampaignName VARCHAR(500) NULL,
    CampaignCode VARCHAR(100) NULL, -- CAM_YYYYMMDD_CampaignId
    Description VARCHAR(500) NULL,
    Creator INT NULL,
    CreatedDate DATETIME NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    StatusId TINYINT NULL, -- 0: Draft, 1: Active, 2: Deactive, 3: Archived
    CONSTRAINT PK_LandingPage_Campaign PRIMARY KEY CLUSTERED (CampaignId)
) 
ON [SettingData];
GO

/*
-- 9. Drop & Create LandingPage_ComponentType
IF OBJECT_ID('dbo.LandingPage_ComponentType', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_ComponentType;
CREATE TABLE LandingPage_ComponentType (
    ComponentTypeId INT NOT NULL IDENTITY(1,1),
    ComponentTypeName VARCHAR(100) NULL,
    CONSTRAINT PK_LandingPage_ComponentType PRIMARY KEY CLUSTERED (ComponentTypeId)
) 
ON [SettingData];
GO

-- 10. Drop & Create LandingPage_Component
IF OBJECT_ID('dbo.LandingPage_Component', 'U') IS NOT NULL DROP TABLE dbo.LandingPage_Component;
CREATE TABLE LandingPage_Component (
    ComponentId INT NOT NULL IDENTITY(1,1),
    ComponentName VARCHAR(200) NULL,
    ComponentType INT NULL, -- FK to LandingPage_ComponentType.ComponentTypeId
    Creator INT NULL,
    CreatedDate DATETIME NULL,
    UpdatedBy INT NULL,
    UpdatedDate DATETIME NULL,
    StatusId TINYINT NULL, -- 0: Active, 1: Inactive
    CONSTRAINT PK_LandingPage_Component PRIMARY KEY CLUSTERED (ComponentId)
) 
ON [SettingData];
GO
*/