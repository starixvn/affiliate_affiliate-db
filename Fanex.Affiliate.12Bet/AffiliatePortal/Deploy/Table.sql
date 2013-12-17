 USE [AffPortal_12BET]
GO

/****** Object:  Table [dbo].[AliasURLs]    Script Date: 11/12/2010 11:37:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
if(exists(select(1) from sys.tables (nolock) where name='AliasURLs'))
	Drop table AliasURLs
GO	

CREATE TABLE [dbo].[AliasURLs](
	[pageId] [uniqueidentifier] NOT NULL,
	[url] [nvarchar](200) NOT NULL,
 CONSTRAINT [PK_AliasURLs] PRIMARY KEY CLUSTERED 
(
	[pageId] ASC,
	[url] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Buckets'))
	Drop table Buckets
GO	

CREATE TABLE [dbo].[Buckets](
	[code] [nvarchar](64) NOT NULL,
	[name] [nvarchar](150) NOT NULL,
	[inBody] [bit] NOT NULL,
	[controlOnDisk] [nvarchar](500) NULL,
 CONSTRAINT [PK_Buckets] PRIMARY KEY CLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Comments'))
	Drop table Comments
GO	
CREATE TABLE [dbo].[Comments](
	[commentId] [bigint] IDENTITY(1,1) NOT NULL,
	[postId] [int] NOT NULL,
	[parentId] [bigint] NULL,
	[siteId] [int] NULL,
	[name] [nvarchar](256) NULL,
	[email] [nvarchar](256) NULL,
	[url] [nvarchar](256) NULL,
	[ip] [nvarchar](100) NULL,
	[content] [nvarchar](max) NOT NULL,
	[status] [tinyint] NOT NULL,
	[createdDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Comments] PRIMARY KEY CLUSTERED 
(
	[commentId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PostData]
) ON [PostData]

GO

if(exists(select(1) from sys.tables (nolock) where name='ELMAH_Error'))
	Drop table ELMAH_Error
GO	
CREATE TABLE [dbo].[ELMAH_Error](
	[ErrorId] [uniqueidentifier] NOT NULL,
	[Application] [nvarchar](60) NOT NULL,
	[Host] [nvarchar](50) NOT NULL,
	[Type] [nvarchar](100) NOT NULL,
	[Source] [nvarchar](60) NOT NULL,
	[Message] [nvarchar](500) NOT NULL,
	[User] [nvarchar](50) NOT NULL,
	[StatusCode] [int] NOT NULL,
	[TimeUtc] [datetime] NOT NULL,
	[Sequence] [int] IDENTITY(1,1) NOT NULL,
	[AllXml] [ntext] NOT NULL,
 CONSTRAINT [PK_ELMAH_Error] PRIMARY KEY NONCLUSTERED 
(
	[ErrorId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ErrorData]
) ON [ErrorData] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[ELMAH_Error] ADD  CONSTRAINT [DF_ELMAH_Error_ErrorId]  DEFAULT (newid()) FOR [ErrorId]
GO
if(exists(select(1) from sys.tables (nolock) where name='EmbeddableInRoles'))
	Drop table EmbeddableInRoles
GO	
CREATE TABLE [dbo].[EmbeddableInRoles](
	[embeddableId] [int] NOT NULL,
	[roleId] [int] NOT NULL,
	[editable] [bit] NOT NULL,
 CONSTRAINT [PK_EmbeddableRoles] PRIMARY KEY CLUSTERED 
(
	[embeddableId] ASC,
	[roleId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='EmbeddableLanguages'))
	Drop table EmbeddableLanguages
GO	
CREATE TABLE [dbo].[EmbeddableLanguages](
	[embeddableId] [int] NOT NULL,
	[languageCode] [nvarchar](10) NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[description] [nvarchar](1024) NOT NULL,
 CONSTRAINT [PK_EmbeddableLanguages] PRIMARY KEY CLUSTERED 
(
	[embeddableId] ASC,
	[languageCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='EmbeddableMeta'))
	Drop table EmbeddableMeta
GO	
CREATE TABLE [dbo].[EmbeddableMeta](
	[embeddableId] [int] NOT NULL,
	[key] [nvarchar](32) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_EmbeddableMeta] PRIMARY KEY CLUSTERED 
(
	[embeddableId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Embeddables'))
	Drop table Embeddables
GO	
CREATE TABLE [dbo].[Embeddables](
	[embeddableId] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[description] [nvarchar](1024) NOT NULL,
	[editable] [bit] NOT NULL,
	[enable] [bit] NOT NULL,
	[isSystem] [bit] NOT NULL,
	[createdBy] [int] NOT NULL,
	[createdDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Embeddables] PRIMARY KEY CLUSTERED 
(
	[embeddableId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='EmbeddableSamples'))
	Drop table EmbeddableSamples
GO
CREATE TABLE [dbo].[EmbeddableSamples](
	[embeddableId] [int] IDENTITY(10000,1) NOT NULL,
	[fromEmbeddableId] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[description] [nvarchar](1024) NOT NULL,
	[editable] [bit] NOT NULL,
	[deletable] [bit] NOT NULL,
	[enable] [bit] NOT NULL,
	[createdBy] [int] NOT NULL,
	[createdDate] [datetime] NOT NULL,
 CONSTRAINT [PK_EmbeddableTemplates] PRIMARY KEY CLUSTERED 
(
	[embeddableId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='EmbeddbleRoles'))
	Drop table EmbeddbleRoles
GO
CREATE TABLE [dbo].[EmbeddbleRoles](
	[roleId] [int] IDENTITY(1,1) NOT NULL,
	[code] [nvarchar](64) NOT NULL,
	[name] [nvarchar](64) NOT NULL,
 CONSTRAINT [PK_EmbeddbleRoles] PRIMARY KEY CLUSTERED 
(
	[roleId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Languages'))
	Drop table Languages
GO

CREATE TABLE [dbo].[Languages](
	[languageId] [int] IDENTITY(1,1) NOT NULL,
	[code] [nvarchar](50) NOT NULL,
	[name] [nvarchar](64) NOT NULL,
	[enable] [bit] NOT NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[languageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA],
 CONSTRAINT [IX_Languages] UNIQUE NONCLUSTERED 
(
	[code] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='LayoutBuckets'))
	Drop table LayoutBuckets
GO
CREATE TABLE [dbo].[LayoutBuckets](
	[layoutId] [int] NOT NULL,
	[bucketCode] [nvarchar](64) NOT NULL,
 CONSTRAINT [PK_LayoutBuckets] PRIMARY KEY CLUSTERED 
(
	[layoutId] ASC,
	[bucketCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
if(exists(select(1) from sys.tables (nolock) where name='Layouts'))
	Drop table Layouts
GO
CREATE TABLE [dbo].[Layouts](
	[layoutId] [int] IDENTITY(1,1) NOT NULL,
	[layoutFile] [nvarchar](256) NOT NULL,
	[isBody] [bit] NOT NULL,
	[description] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_Layouts] PRIMARY KEY CLUSTERED 
(
	[layoutId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Menu'))
	Drop table Menu
GO
CREATE TABLE [dbo].[Menu](
	[menuId] [int] IDENTITY(1,1) NOT NULL,
	[siteId] [int] NOT NULL,
	[parentId] [int] NOT NULL,
	[level] [int] NOT NULL,
	[orderNo] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[link] [nvarchar](256) NOT NULL,
	[pageId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Menus] PRIMARY KEY CLUSTERED 
(
	[menuId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='MenuHistories'))
	Drop table MenuHistories
GO
CREATE TABLE [dbo].[MenuHistories](
	[menuId] [int] IDENTITY(1,1) NOT NULL,
	[versionId] [int] NOT NULL,
	[siteId] [int] NOT NULL,
	[parentId] [int] NOT NULL,
	[level] [int] NOT NULL,
	[orderNo] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[link] [nvarchar](256) NOT NULL,
	[pageId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_MenuHistories] PRIMARY KEY CLUSTERED 
(
	[menuId] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='MenuTemps'))
	Drop table MenuTemps
GO
CREATE TABLE [dbo].[MenuTemps](
	[menuId] [int] IDENTITY(1,1) NOT NULL,
	[siteId] [int] NOT NULL,
	[parentId] [int] NOT NULL,
	[level] [int] NOT NULL,
	[orderNo] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[link] [nvarchar](256) NOT NULL,
	[pageId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_MenuTemps] PRIMARY KEY CLUSTERED 
(
	[menuId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='Messages'))
	Drop table Messages
GO
CREATE TABLE [dbo].[Messages](
	[messageId] [int] IDENTITY(1,1) NOT NULL,
	[fromSiteId] [int] NOT NULL,
	[toSiteId] [int] NOT NULL,
	[title] [nvarchar](256) NOT NULL,
	[content] [nvarchar](max) NOT NULL,
	[isRead] [bit] NOT NULL,
	[isDeleted] [bit] NOT NULL,
	[createdDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED 
(
	[messageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PostData]
) ON [PostData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddableHistories'))
	Drop table PageEmbeddableHistories
GO
CREATE TABLE [dbo].[PageEmbeddableHistories](
	[instanceId] [int] IDENTITY(1,1) NOT NULL,
	[versionId] [int] NOT NULL,
	[pageId] [uniqueidentifier] NOT NULL,
	[bucket] [nvarchar](64) NOT NULL,
	[embeddableId] [int] NOT NULL,
	[title] [nvarchar](256) NOT NULL,
	[status] [smallint] NOT NULL,
	[orderNo] [smallint] NOT NULL,
 CONSTRAINT [PK_PageEmbeddableHistories] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddableMeta'))
	Drop table PageEmbeddableMeta
GO
CREATE TABLE [dbo].[PageEmbeddableMeta](
	[instanceId] [int] NOT NULL,
	[key] [nvarchar](32) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_EmbeddableInstances] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddableMetaHistories'))
	Drop table PageEmbeddableMetaHistories
GO

CREATE TABLE [dbo].[PageEmbeddableMetaHistories](
	[instanceId] [int] NOT NULL,
	[key] [nvarchar](32) NOT NULL,
	[versionId] [int] NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_PageEmbeddableMetaHistories] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC,
	[key] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddableMetaTemps'))
	Drop table PageEmbeddableMetaTemps
GO

CREATE TABLE [dbo].[PageEmbeddableMetaTemps](
	[instanceId] [int] NOT NULL,
	[key] [nvarchar](32) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_PageEmbeddableMetaTemps] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddables'))
	Drop table PageEmbeddables
GO

CREATE TABLE [dbo].[PageEmbeddables](
	[instanceId] [int] IDENTITY(1,1) NOT NULL,
	[pageId] [uniqueidentifier] NOT NULL,
	[bucket] [nvarchar](64) NOT NULL,
	[embeddableId] [int] NOT NULL,
	[title] [nvarchar](256) NOT NULL,
	[status] [smallint] NOT NULL,
	[orderNo] [smallint] NOT NULL,
 CONSTRAINT [PK_PageEmbeddables] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageEmbeddableTemps'))
	Drop table PageEmbeddableTemps
GO

CREATE TABLE [dbo].[PageEmbeddableTemps](
	[instanceId] [int] IDENTITY(1,1) NOT NULL,
	[pageId] [uniqueidentifier] NOT NULL,
	[bucket] [nvarchar](64) NOT NULL,
	[embeddableId] [int] NOT NULL,
	[title] [nvarchar](256) NOT NULL,
	[status] [smallint] NOT NULL,
	[orderNo] [smallint] NOT NULL,
 CONSTRAINT [PK_PageEmbeddableTemps] PRIMARY KEY CLUSTERED 
(
	[instanceId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageHistories'))
	Drop table PageHistories
GO
CREATE TABLE [dbo].[PageHistories](
	[pageId] [uniqueidentifier] NOT NULL,
	[siteId] [int] NOT NULL,
	[versionId] [int] NOT NULL,
	[url] [nvarchar](256) NOT NULL,
	[title] [nvarchar](150) NOT NULL,
	[masterId] [uniqueidentifier] NULL,
	[enable] [bit] NOT NULL,
	[createdDate] [datetime] NOT NULL,
	[updatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PageHistories] PRIMARY KEY CLUSTERED 
(
	[pageId] ASC,
	[siteId] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO

if(exists(select(1) from sys.tables (nolock) where name='Pages'))
	Drop table Pages
GO
CREATE TABLE [dbo].[Pages](
	[pageId] [uniqueidentifier] NOT NULL,
	[siteId] [int] NOT NULL,
	[url] [nvarchar](256) NOT NULL,
	[title] [nvarchar](150) NOT NULL,
	[masterId] [uniqueidentifier] NULL,
	[enable] [bit] NOT NULL,
	[createdDate] [datetime] NOT NULL,
	[updatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_Pages] PRIMARY KEY CLUSTERED 
(
	[pageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData],
 CONSTRAINT [IX_Pages_UniqueUrl] UNIQUE NONCLUSTERED 
(
	[siteId] ASC,
	[url] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='PageTemps'))
	Drop table PageTemps
GO
CREATE TABLE [dbo].[PageTemps](
	[pageId] [uniqueidentifier] NOT NULL,
	[siteId] [int] NOT NULL,
	[url] [nvarchar](256) NOT NULL,
	[title] [nvarchar](150) NOT NULL,
	[masterId] [uniqueidentifier] NULL,
	[enable] [bit] NOT NULL,
	[createdDate] [datetime] NOT NULL,
	[updatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_PageTemps] PRIMARY KEY CLUSTERED 
(
	[pageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData],
 CONSTRAINT [IX_PageTemps_UniqueUrl] UNIQUE NONCLUSTERED 
(
	[siteId] ASC,
	[url] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='Posts'))
	Drop table Posts
GO
CREATE TABLE [dbo].[Posts](
	[postId] [int] IDENTITY(1,1) NOT NULL,
	[siteId] [int] NOT NULL,
	[title] [nvarchar](256) NOT NULL,
	[description] [nvarchar](1024) NULL,
	[content] [nvarchar](max) NOT NULL,
	[type] [tinyint] NOT NULL,
	[status] [tinyint] NOT NULL,
	[createdDate] [datetime] NOT NULL,
	[updatedDate] [datetime] NOT NULL,
	[parentId] [int] NULL,
 CONSTRAINT [PK_Posts] PRIMARY KEY CLUSTERED 
(
	[postId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PostData]
) ON [PostData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SEOMetaData'))
	Drop table SEOMetaData
GO
CREATE TABLE [dbo].[SEOMetaData](
	[pageId] [uniqueidentifier] NOT NULL,
	[keywords] [nvarchar](200) NULL,
	[description] [nvarchar](200) NULL,
	[visible] [bit] NOT NULL,
	[followLinks] [bit] NOT NULL,
 CONSTRAINT [PK_SEOMetaData] PRIMARY KEY CLUSTERED 
(
	[pageId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO

ALTER TABLE [dbo].[SEOMetaData] ADD  CONSTRAINT [DF_SEOMetaData_visible]  DEFAULT ((1)) FOR [visible]
GO

ALTER TABLE [dbo].[SEOMetaData] ADD  CONSTRAINT [DF_SEOMetaData_followLinks]  DEFAULT ((1)) FOR [followLinks]
GO
if(exists(select(1) from sys.tables (nolock) where name='SiteHistories'))
	Drop table SiteHistories
GO
CREATE TABLE [dbo].[SiteHistories](
	[siteId] [int] NOT NULL,
	[versionId] [int] NOT NULL,
	[siteName] [nvarchar](256) NOT NULL,
	[siteHost] [nvarchar](256) NOT NULL,
	[siteTitle] [nvarchar](256) NOT NULL,
	[displayName] [nvarchar](256) NOT NULL,
	[copyright] [nvarchar](4000) NOT NULL,
	[bodyLayoutId] [int] NOT NULL,
	[footerLayoutId] [int] NOT NULL,
	[homePageId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_SiteHistories] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteMeta'))
	Drop table SiteMeta
GO
CREATE TABLE [dbo].[SiteMeta](
	[siteId] [int] NOT NULL,
	[key] [nvarchar](64) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_SiteMeta] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteMetaHistories'))
	Drop table SiteMetaHistories
GO
CREATE TABLE [dbo].[SiteMetaHistories](
	[siteId] [int] NOT NULL,
	[key] [nvarchar](64) NOT NULL,
	[versionId] [int] NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_SiteMetaHistories] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC,
	[key] ASC,
	[versionId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [HistorySiteData]
) ON [HistorySiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteMetaTemps'))
	Drop table SiteMetaTemps
GO
CREATE TABLE [dbo].[SiteMetaTemps](
	[siteId] [int] NOT NULL,
	[key] [nvarchar](64) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_SiteMetaTemps] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteOption'))
	Drop table SiteOption
GO
CREATE TABLE [dbo].[SiteOption](
	[name] [nvarchar](256) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
	[enable] [bit] NOT NULL,
 CONSTRAINT [PK_SiteOption] PRIMARY KEY CLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='Sites'))
	Drop table Sites
GO
CREATE TABLE [dbo].[Sites](
	[siteId] [int] NOT NULL,
	[siteName] [nvarchar](256) NOT NULL,
	[siteHost] [nvarchar](256) NOT NULL,
	[siteTitle] [nvarchar](256) NOT NULL,
	[displayName] [nvarchar](256) NOT NULL,
	[copyright] [nvarchar](4000) NOT NULL,
	[currentRevision] [int] NOT NULL,
	[bodyLayoutId] [int] NOT NULL,
	[footerLayoutId] [int] NOT NULL,
	[homePageId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Sites] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData],
 CONSTRAINT [IX_Sites_SiteHost] UNIQUE NONCLUSTERED 
(
	[siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteTemps'))
	Drop table SiteTemps
GO
CREATE TABLE [dbo].[SiteTemps](
	[siteId] [int] NOT NULL,
	[siteName] [nvarchar](256) NOT NULL,
	[siteHost] [nvarchar](256) NOT NULL,
	[siteTitle] [nvarchar](256) NOT NULL,
	[displayName] [nvarchar](256) NOT NULL,
	[copyright] [nvarchar](4000) NOT NULL,
	[currentRevision] [int] NOT NULL,
	[bodyLayoutId] [int] NOT NULL,
	[footerLayoutId] [int] NOT NULL,
	[homePageId] [uniqueidentifier] NOT NULL,
	[requestApprove] [bit] NULL,
	[requestApproveDate] [datetime] NULL,
 CONSTRAINT [PK_SiteTemps] PRIMARY KEY CLUSTERED 
(
	[siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData],
 CONSTRAINT [IX_SiteTemps_SiteHost] UNIQUE NONCLUSTERED 
(
	[siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TempSiteData]
) ON [TempSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='SiteVersions'))
	Drop table SiteVersions
GO
CREATE TABLE [dbo].[SiteVersions](
	[versionId] [int] NOT NULL,
	[siteId] [int] NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_SiteVersions] PRIMARY KEY CLUSTERED 
(
	[versionId] ASC,
	[siteId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='Taxonomy'))
	Drop table Taxonomy
GO
CREATE TABLE [dbo].[Taxonomy](
	[taxonomyId] [int] IDENTITY(1,1) NOT NULL,
	[termId] [int] NOT NULL,
	[name] [nvarchar](32) NOT NULL,
	[parentId] [int] NOT NULL,
	[count] [int] NOT NULL,
 CONSTRAINT [PK_Taxonomies] PRIMARY KEY CLUSTERED 
(
	[taxonomyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='TermLanguages'))
	Drop table TermLanguages
GO
CREATE TABLE [dbo].[TermLanguages](
	[termId] [int] NOT NULL,
	[languageCode] [nvarchar](10) NOT NULL,
	[term] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_TermLanguages] PRIMARY KEY CLUSTERED 
(
	[termId] ASC,
	[languageCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO

if(exists(select(1) from sys.tables (nolock) where name='TermRelationships'))
	Drop table TermRelationships
GO
CREATE TABLE [dbo].[TermRelationships](
	[objectId] [int] NOT NULL,
	[taxonomyId] [int] NOT NULL,
	[orderNo] [int] NOT NULL,
 CONSTRAINT [PK_Terms] PRIMARY KEY CLUSTERED 
(
	[objectId] ASC,
	[taxonomyId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='Terms'))
	Drop table Terms
GO
CREATE TABLE [dbo].[Terms](
	[termId] [int] IDENTITY(1,1) NOT NULL,
	[siteId] [int] NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[slug] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_Terms_1] PRIMARY KEY CLUSTERED 
(
	[termId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MainSiteData]
) ON [MainSiteData]

GO
if(exists(select(1) from sys.tables (nolock) where name='ThemeLanguages'))
	Drop table ThemeLanguages
GO
CREATE TABLE [dbo].[ThemeLanguages](
	[themeId] [int] NOT NULL,
	[languageCode] [nvarchar](10) NOT NULL,
	[name] [nvarchar](256) NOT NULL,
 CONSTRAINT [PK_ThemeLanguages] PRIMARY KEY CLUSTERED 
(
	[themeId] ASC,
	[languageCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO

if(exists(select(1) from sys.tables (nolock) where name='Themes'))
	Drop table Themes
GO
CREATE TABLE [dbo].[Themes](
	[themeId] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](256) NOT NULL,
	[folder] [nvarchar](64) NOT NULL,
	[enable] [bit] NOT NULL,
	[level] [int] NOT NULL,
 CONSTRAINT [PK_Themes] PRIMARY KEY CLUSTERED 
(
	[themeId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
if(exists(select(1) from sys.tables (nolock) where name='ThemesMeta'))
	Drop table ThemesMeta
GO
CREATE TABLE [dbo].[ThemesMeta](
	[themeId] [int] NOT NULL,
	[key] [nvarchar](64) NOT NULL,
	[value] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_ThemesMeta] PRIMARY KEY CLUSTERED 
(
	[themeId] ASC,
	[key] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO




