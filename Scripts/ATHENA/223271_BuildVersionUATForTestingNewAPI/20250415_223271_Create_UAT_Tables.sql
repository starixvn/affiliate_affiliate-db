/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*	Revisions:
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/

-- MemberInfo_UAT Table
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberInfo_UAT](
	[UserName] [varchar](30) NOT NULL,
	[AffID] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[RegisteredDate] [datetime] NULL,
	[DepositCustID] [int] NULL,
	[Currency] [smallint] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[IsRemoved] [bit] NOT NULL,
	[IBCCustID] [int] NULL,
	[IBCUserName] [varchar](30) NULL,
	[Recommend] [int] NULL,
	[Btag] [varchar](100) NULL,
	[ClickID] [bigint] NULL,
	[CountryID] [varchar](8) NULL,
	[Phone] [varchar](20) NULL,
	[Address] [nvarchar](255) NULL,
	[AffAffectedDate] [datetime] NULL,
 CONSTRAINT [PK_MemberInfo_UAT] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
CREATE NONCLUSTERED INDEX [IX_AffID_UAT] ON [dbo].[MemberInfo_UAT]
(
	[AffID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AccInfoIndex]
GO
CREATE NONCLUSTERED INDEX [IX_ClickID_UAT] ON [dbo].[MemberInfo_UAT]
(
	[ClickID] ASC
)
INCLUDE([CreatedDate],[RegisteredDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [AccInfoIndex]
GO
ALTER TABLE [dbo].[MemberInfo_UAT] ADD  CONSTRAINT [DF_MemberInfo_UAT_IsRemoved]  DEFAULT ((0)) FOR [IsRemoved]
GO
ALTER TABLE [dbo].[MemberInfo_UAT] ADD  CONSTRAINT [DF_MemberInfo_UAT_Recommend]  DEFAULT ((0)) FOR [Recommend]
GO

-- ClickStatistics_UAT Table
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatistics_UAT](
	[ClickID] [bigint] IDENTITY(1,1) NOT NULL,
	[AffID] [int] NOT NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[IP] [varchar](23) NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[Browser] [nvarchar](50) NOT NULL,
	[URLReferrer] [nvarchar](300) NOT NULL,
	[DomainReferrer] [nvarchar](300) NOT NULL,
	[OS] [nvarchar](50) NULL,
	[Device] [nvarchar](50) NULL,
	[BrowserVersion] [nvarchar](16) NULL,
	[BrowserResolution] [nvarchar](16) NULL,
	[BrowserLanguage] [nvarchar](8) NULL,
	[UserAgent] [nvarchar](256) NULL,
	[Country] [nvarchar](256) NULL,
	[LanguageCode] [varchar](5) NULL,
	[SportCode] [varchar](50) NULL,
	[RedirectURL] [nvarchar](256) NULL,
	[Status] [tinyint] NULL,
	[ClickCount] [int] NULL
) ON [StatData]
GO
ALTER TABLE [dbo].[ClickStatistics_UAT] ADD  CONSTRAINT [DF_ClickStatistics_UAT_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[ClickStatistics_UAT] ADD  CONSTRAINT [DF_ClickStatistics_UAT_ClickCount]  DEFAULT ((1)) FOR [ClickCount]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0: not signup; 1: signup; 2: deposited' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ClickStatistics_UAT', @level2type=N'COLUMN',@level2name=N'Status'
GO

-- CurrencyConverter_UAT Table
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CurrencyConverter_UAT](
	[ApplicationID] [smallint] NOT NULL,
	[PartnerCurrency] [varchar](50) NOT NULL,
	[ExchangeID] [smallint] NULL,
	[CreatedDate] [datetime] NULL,
	[PartnerExchangeID] [smallint] NULL,
 CONSTRAINT [PK_CurrencyConverter_UAT] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC,
	[PartnerCurrency] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO
ALTER TABLE [dbo].[CurrencyConverter_UAT] ADD  CONSTRAINT [DF_CurrencyConverter_UAT_ApplicationID]  DEFAULT ((1)) FOR [ApplicationID]
GO

-- AffInfo_UAT Table
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffInfo_UAT](
	[AffID] [int] IDENTITY(10001,1) NOT NULL,
	[UserName] [nvarchar](30) NOT NULL,
	[UserName2] [nvarchar](30) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[GroupID] [int] NULL,
	[Status] [varchar](30) NULL,
	[ApprovedDate] [smalldatetime] NULL,
	[IsClosed] [bit] NULL,
	[Currency] [smallint] NULL,
	[RegisteredDate] [smalldatetime] NULL,
	[Email] [nvarchar](50) NULL,
	[Password] [varchar](40) NULL,
	[AffType] [tinyint] NULL,
	[IsPageEnabled] [bit] NULL,
	[Level] [tinyint] NULL,
	[IsLocked] [bit] NULL,
	[TestLevel] [tinyint] NULL,
	[BF] [money] NULL,
	[TotalMembers] [int] NULL,
 CONSTRAINT [PK_AffInfo_UAT] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoData]
) ON [AccInfoData]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_Affiliate_AffInfo_UAT_GroupID]  DEFAULT ((0)) FOR [GroupID]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_Affiliate_AffInfo_UAT_IsClosed]  DEFAULT ((0)) FOR [IsClosed]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_AffInfo_UAT_AffType]  DEFAULT ((1)) FOR [AffType]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_AffInfo_UAT_IsPageEnabled]  DEFAULT ((0)) FOR [IsPageEnabled]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_AffInfo_UAT_IsLocked]  DEFAULT ((0)) FOR [IsLocked]
GO

ALTER TABLE [dbo].[AffInfo_UAT] ADD  CONSTRAINT [DF_Affiliate_AffInfo_UAT_TestLevel]  DEFAULT ((0)) FOR [TestLevel]
GO

