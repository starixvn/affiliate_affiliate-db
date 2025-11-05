/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: 20250623@Lewis
    DB: DBAFF12B-Affiliate_12B
    Task: Step1 SettingTables DDL and initial data for CPAGroupSetting, CPAProductSetting, CPATierSetting, CommGroup, GroupType
*/

-- CPAGroupSetting table
CREATE TABLE CPAGroupSetting (
    ID int IDENTITY(1,1) NOT NULL,
    FromDate datetime NULL,
    ToDate datetime NULL,
    GroupId int NULL,
    GroupTypeId int NULL,
    SubCommRate decimal(9,8) NULL,
    ActiveDays smallint NULL,
    HoldingDays smallint NULL,
    HoldingTickets smallint NULL,
    Quota smallint NULL,
    CountryCodes varchar(4000) NULL,
    IsInstant bit NULL,
    CONSTRAINT PK_CPAGroupSetting_ID PRIMARY KEY NONCLUSTERED (ID)
) ON [SettingData];
GO

-- CPAProductSetting table
CREATE TABLE CPAProductSetting (
    ID int IDENTITY(1,1) NOT NULL,
    FromDate datetime NULL,
    ToDate datetime NULL,
    GroupId int NULL,
    GroupProductId int NULL,
    ProductId int NULL,
    CONSTRAINT PK_CPAProductSetting_ID PRIMARY KEY NONCLUSTERED (ID)
) ON [SettingData];
GO

-- CPATierSetting table
CREATE TABLE CPATierSetting (
    ID int IDENTITY(1,1) NOT NULL,
    FromDate datetime NULL,
    ToDate datetime NULL,
    GroupId int NULL,
    GroupProductId tinyint NULL,
    TierId int NULL,
    MinFDM money NULL,
    MaxFDM money NULL,
    MinTotalDeposit money NULL,
    MaxTotalDeposit money NULL,
    MinTO money NULL,
    MaxTO money NULL,
    CPAAmount money NULL,
    CONSTRAINT PK_CPATierSetting_ID PRIMARY KEY NONCLUSTERED (ID)
) ON [SettingData];
GO

-- CommGroup: Add columns for CPA
ALTER TABLE CommGroup
ADD ActiveDays smallint NULL,
    HoldingDays smallint NULL,
    HoldingTickets smallint NULL,
    Quota smallint NULL,
    CountryCodes varchar(4000) NULL,
    IsInstant bit NULL,
    UpdatedBy INT NULL,
    UpdatedTime DATETIME NULL;
GO

-- GroupType: Add IsEnabled column
ALTER TABLE GroupType
ADD IsEnabled bit NOT NULL CONSTRAINT DF_GroupType_IsEnabled DEFAULT 1;
GO

-- Indexes for CPA tables
CREATE CLUSTERED INDEX IX_CPAGroupSetting_GroupId_ToDate ON CPAGroupSetting (GroupId, ToDate) ON [SettingData];
CREATE CLUSTERED INDEX IX_CPAProductSetting_GroupId_ToDate ON CPAProductSetting (GroupId, ToDate) ON [SettingData];
CREATE CLUSTERED INDEX IX_CPATierSetting_GroupId_ToDate ON CPATierSetting (GroupId, ToDate) ON [SettingData];
GO

-- Initial data for GroupType
INSERT INTO GroupType (GroupTypeBy, GroupTypeName, DisplayOrder, IsEnabled)
VALUES
    ('Turnover', 'Calculate Revenue Share by Turnover', 2, 0),
    ('CPA', 'CPA', 3, 1),
    ('CPA_Winloss', 'Hybrid CPA/Revenue Share', 4, 1);
GO

-- End of Step1_SettingTables.sql
