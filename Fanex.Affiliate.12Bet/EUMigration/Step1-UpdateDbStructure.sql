/*
	Task : 12Bet - EU migration: Update DB structure
	Author : Bobby.Nguyen@20140124
	DB: Affiliate_12Bet
*/
USE [Affiliate_12BET];
GO

/** update structure of AffInfo **/
IF NOT EXISTS (
		SELECT 1
		FROM sys.columns
		WHERE [name] = N'ForceChangePass'
			AND [object_id] = OBJECT_ID(N'AffInfo')
		)
BEGIN
	ALTER TABLE dbo.AffInfo ADD ForceChangePass BIT DEFAULT(0);
END

IF NOT EXISTS (
		SELECT 1
		FROM sys.columns
		WHERE [name] = N'EUAffID'
			AND [object_id] = OBJECT_ID(N'AffInfo')
		)
BEGIN
	ALTER TABLE dbo.AffInfo ADD EUAffID INT;
END
GO

/** update structure of AffDetail **/
ALTER TABLE dbo.AffDetail
ALTER COLUMN [Address] NVARCHAR(250)

ALTER TABLE dbo.AffDetail
ALTER COLUMN [City] NVARCHAR(250)

ALTER TABLE dbo.AffDetail
ALTER COLUMN [Player_Username] VARCHAR(100)
GO

/** update structure of MemberInfo **/
IF NOT EXISTS (
		SELECT 1
		FROM sys.columns
		WHERE [name] = N'EUAffID'
			AND [object_id] = OBJECT_ID(N'MemberInfo')
		)
BEGIN
	ALTER TABLE dbo.MemberInfo ADD EUAffID INT;
END

IF NOT EXISTS (
		SELECT 1
		FROM sys.columns
		WHERE [name] = N'AffAffectedDate'
			AND [object_id] = OBJECT_ID(N'MemberInfo')
		)
BEGIN
	ALTER TABLE dbo.MemberInfo ADD AffAffectedDate DATETIME;
END
GO

/** update structure of Banner_1 **/
IF NOT EXISTS (
		SELECT 1
		FROM sys.columns
		WHERE [name] = N'AffType'
			AND [object_id] = OBJECT_ID(N'Banners_1')
		)
BEGIN
	ALTER TABLE dbo.Banners_1 ADD AffType INT;
END
GO

/* script to correct data*/
--delete [Product]
IF (EXISTS (SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'Product'
			)
		)
BEGIN 
	IF (EXISTS (SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'Product_bk'
			)
		) DROP TABLE [dbo].[Product_bk];
	SELECT * 
	INTO Product_bk
	FROM [dbo].[Product];

	DROP TABLE [dbo].[Product];
END
--delete [AffType]
IF (EXISTS (SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'AffType'
			)
		)
BEGIN 
	IF (EXISTS (SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'AffType_bk'
			)
		) DROP TABLE [dbo].[AffType_bk];
	SELECT * 
	INTO AffType_bk
	FROM [dbo].[AffType];

	DROP TABLE [dbo].[AffType];
END
GO

--correct AffType & Product
CREATE TABLE [dbo].[AffType](
	[TypeId] [int] NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Description] [nvarchar](250) NULL,
	[CreatedDate] [datetime] NULL,
	[Creater] [int] NULL,
 CONSTRAINT [PK_AffType] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Product]    Script Date: 2/26/2014 1:54:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Product](
	[TypeId] [int] NOT NULL,
	[TypeName] [nvarchar](100) NULL,
	[ListSport] [nvarchar](50) NULL
) ON [PRIMARY]

GO
INSERT [dbo].[AffType] ([TypeId], [Name], [Description], [CreatedDate], [Creater]) VALUES (2, N'Asian', N'Asian Affiliate', CAST(0x0000A2D200000000 AS DateTime), 1)
GO
INSERT [dbo].[AffType] ([TypeId], [Name], [Description], [CreatedDate], [Creater]) VALUES (3, N'Media', N'Media Affiliate', CAST(0x0000A2D200000000 AS DateTime), 1)
GO
INSERT [dbo].[AffType] ([TypeId], [Name], [Description], [CreatedDate], [Creater]) VALUES (4, N'European', N'European Affiliate', CAST(0x0000A2D200000000 AS DateTime), 1)
GO
INSERT [dbo].[AffType] ([TypeId], [Name], [Description], [CreatedDate], [Creater]) VALUES (5, N'Korean', N'Korean Affiliate', CAST(0x0000A2D200000000 AS DateTime), 1)
GO
INSERT [dbo].[AffType] ([TypeId], [Name], [Description], [CreatedDate], [Creater]) VALUES (6, N'Japanese', N'Japanese Affiliate', CAST(0x0000A2D200000000 AS DateTime), 1)
GO
INSERT [dbo].[Product] ([TypeId], [TypeName], [ListSport]) VALUES (0, N'Sportbook', N'1')
GO
INSERT [dbo].[Product] ([TypeId], [TypeName], [ListSport]) VALUES (1, N'Casino', N'3')
GO
INSERT [dbo].[Product] ([TypeId], [TypeName], [ListSport]) VALUES (2, N'Sportbook and Casino', N'1,3')
GO

--Update Asean affiliate
UPDATE ai
SET AffType = 2
FROM dbo.AffInfo ai WITH(ROWLOCK ,UPDLOCK)
WHERE AffType = 0

--Update Media affiliate
UPDATE ai
SET AffType = 3
FROM dbo.AffInfo ai WITH(ROWLOCK ,UPDLOCK)
WHERE AffType = 2

--Update AffType to Asean AFF
UPDATE bn
SET AffType = 2
FROM dbo.Banners_1 bn WITH(ROWLOCK ,UPDLOCK)





