USE Affiliate_N8G
GO

DROP TABLE dbo.CommGroup
GO

CREATE TABLE dbo.CommGroup
(
	GroupId INT IDENTITY(1,1) NOT NULL,
	GroupName NVARCHAR(100),
	Description NVARCHAR(100),
	Creator INT,
	CreatedDate DATETIME CONSTRAINT [DF_CommGroup_CreatedDate] DEFAULT (GETDATE()),
	IsPrivate BIT CONSTRAINT [DF_CommGroup_IsPrivate] DEFAULT ((0)),
	IsDeleted BIT CONSTRAINT [DF_CommGroup_IsDeleted] DEFAULT ((0)),
	CONSTRAINT [PK_CommGroup] PRIMARY KEY CLUSTERED
	(
		GroupId ASC
	) ON SettingData
) ON SettingData
GO

INSERT INTO dbo.CommGroup (GroupName, Creator, IsPrivate, IsDeleted, Description)
SELECT 'Default', 35915769, 0, 0, 'Default System Commission Group'
UNION ALL SELECT 'NoCommission', 35915769, 0, 0, 'Group for all zero commission/closed affiliates'
GO

DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
WHERE GroupId NOT IN (1,2)
GO
DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-02-29' AND GroupId NOT IN (1,2)
GO
DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
WHERE GroupId NOT IN (1,2)
GO
DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-02-29' AND GroupId NOT IN (1,2)
GO



USE Affiliate_N8B
GO

DROP TABLE dbo.CommGroup
GO

CREATE TABLE dbo.CommGroup
(
	GroupId INT IDENTITY(1,1) NOT NULL,
	GroupName NVARCHAR(100),
	Description NVARCHAR(100),
	Creator INT,
	CreatedDate DATETIME CONSTRAINT [DF_CommGroup_CreatedDate] DEFAULT (GETDATE()),
	IsPrivate BIT CONSTRAINT [DF_CommGroup_IsPrivate] DEFAULT ((0)),
	IsDeleted BIT CONSTRAINT [DF_CommGroup_IsDeleted] DEFAULT ((0)),
	CONSTRAINT [PK_CommGroup] PRIMARY KEY CLUSTERED
	(
		GroupId ASC
	) ON SettingData
) ON SettingData
GO

INSERT INTO dbo.CommGroup (GroupName, Creator, IsPrivate, IsDeleted, Description)
SELECT 'Default', 35915769, 0, 0, 'Default System Commission Group'
UNION ALL SELECT 'NoCommission', 35915769, 0, 0, 'Group for all zero commission/closed affiliates'
GO

DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
WHERE GroupId NOT IN (1,2)
GO
DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-02-29' AND GroupId NOT IN (1,2)
GO
DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
WHERE GroupId NOT IN (1,2)
GO
DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-02-29' AND GroupId NOT IN (1,2)
GO