/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support new Aff Yashbet
		2. Create Table DB Affiliate_YashBet
*/
/****** Object:  Table [dbo].[ExchangeOanda]    Script Date: 1/8/2024 12:01:16 AM ******/
USE Affiliate_YashBet
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExchangeOanda](
	[ExchangeDate] [smalldatetime] NOT NULL,
	[ExchangeId] [int] NOT NULL,
	[Code] [varchar](5) NULL,
	[ActualRate] [float] NULL,
	[VND] [float] NULL,
	[EUR] [float] NULL,
	[USD] [float] NULL,
	[CNY] [float] NULL,
	[MYR] [float] NULL,
	[THB] [float] NULL,
	[IDR] [float] NULL,
	[BDT] [float] NULL,
	[INR] [float] NULL,
 CONSTRAINT [PK_ExchangeOanda] PRIMARY KEY CLUSTERED 
(
	[ExchangeDate] ASC,
	[ExchangeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[TpExchange]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpExchange](
	[TpExchangeId] [int] NOT NULL,
	[ExchangeId] [int] NULL,
 CONSTRAINT [PK_TpExchange] PRIMARY KEY NONCLUSTERED 
(
	[TpExchangeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[SystemSettings]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[SID] [int] IDENTITY(1,1) NOT NULL,
	[SName] [varchar](50) NULL,
	[SValue] [varchar](200) NULL,
 CONSTRAINT [PK_SystemSettings] PRIMARY KEY CLUSTERED 
(
	[SID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO

/****** Object:  Table [dbo].[AffTrans]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffTrans](
	[TransId] [bigint] IDENTITY(1,1) NOT NULL,
	[AffId] [int] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Amount] [money] NULL,
	[Status] [varchar](50) NULL,
	[Description] [nvarchar](300) NULL,
	[Creator] [int] NULL,
	[TransType] [int] NULL,
	[RefId] [bigint] NULL,
	[AffCurrency] [int] NULL,
	[AffRate] [float] NULL,
 CONSTRAINT [PK_AffTrans] PRIMARY KEY NONCLUSTERED 
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_AffId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_AffId] ON [dbo].[AffTrans]
(
	[AffId] ASC,
	[TransDate] ASC,
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO

/****** Object:  Table [dbo].[AdminFavorite]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminFavorite](
	[AdminId] [int] NOT NULL,
	[AffId] [int] NOT NULL,
 CONSTRAINT [PK_AdminFavorite] PRIMARY KEY CLUSTERED 
(
	[AdminId] ASC,
	[AffId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AdminNotes]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminNotes](
	[NoteID] [int] IDENTITY(1,1) NOT NULL,
	[Note] [nvarchar](1000) NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
	[AffID] [int] NOT NULL,
	[UpdatedBy] [int] NOT NULL,
 CONSTRAINT [PK_AdminNotes] PRIMARY KEY CLUSTERED 
(
	[NoteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AffDetail]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDetail](
	[AffId] [int] NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[SiteURL] [varchar](100) NOT NULL,
	[MoreSiteURLs] [varchar](1000) NULL,
	[PreferredLanguage] [varchar](11) NULL,
	[Gender] [bit] NULL,
	[Address] [nvarchar](250) NULL,
	[Postal] [nvarchar](50) NULL,
	[City] [nvarchar](250) NULL,
	[State] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[Phone] [varchar](50) NULL,
	[MobilePhone] [varchar](50) NULL,
	[Fax] [varchar](50) NULL,
	[Question] [nvarchar](300) NULL,
	[Answer] [nvarchar](300) NULL,
	[PreferredPayment] [varchar](20) NULL,
	[Player_Username] [varchar](30) NULL,
	[Player_Currency] [int] NULL,
	[Neteller_AccountID] [varchar](50) NULL,
	[Moneybookers_Email] [nvarchar](50) NULL,
	[Wire_BankName] [nvarchar](100) NULL,
	[Wire_BankAddress] [nvarchar](200) NULL,
	[Wire_SwiftCode] [nvarchar](50) NULL,
	[Wire_AccountName] [nvarchar](100) NULL,
	[Wire_AccountNo] [varchar](100) NULL,
	[Cheque_FullName] [nvarchar](200) NULL,
	[Cheque_Address] [nvarchar](200) NULL,
	[Cheque_City] [nvarchar](50) NULL,
	[Cheque_State] [nvarchar](50) NULL,
	[Cheque_Postal] [nvarchar](50) NULL,
	[Cheque_Country] [nvarchar](50) NULL,
	[BonusCode] [varchar](20) NULL,
	[LastLoginDate] [datetime] NULL,
	[LastLoginIP] [nvarchar](20) NULL,
	[LoginCount] [tinyint] NULL,
	[ValidCode] [nvarchar](30) NULL,
	[CodeExpiry] [datetime] NULL,
	[MailOption] [bit] NULL,
	[NoSiteDesc] [nvarchar](1000) NULL,
	[ContactApps] [nvarchar](2000) NULL,
	[QuestionID] [tinyint] NULL,
	[Player_CurrencyName] [nvarchar](50) NULL,
	[Player_CurrencyCode] [varchar](3) NULL,
	[Player_CustId] [int] NULL,
	[TransferLimit] [money] NULL,
	[DisabledTransfer] [bit] NULL,
 CONSTRAINT [PK_AffDetail] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AffDomain]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDomain](
	[DomainId] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
	[IsDeleted] [bit] NULL,
	[IsSSL] [bit] NULL,
 CONSTRAINT [PK_AffDomain] PRIMARY KEY CLUSTERED 
(
	[DomainId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffFunctionInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffFunctionInfo](
	[FuncId] [int] IDENTITY(100000,1) NOT NULL,
	[FuncName] [nvarchar](50) NULL,
	[FuncNote] [nvarchar](2000) NULL,
	[FuncDesc] [nvarchar](50) NULL,
	[FuncRender] [tinyint] NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[DisplayOrder] [tinyint] NULL,
	[Creator] [int] NULL,
	[ParentId] [int] NULL,
	[FileNames] [varchar](2000) NULL,
 CONSTRAINT [PK_AffFunctionInfo] PRIMARY KEY CLUSTERED 
(
	[FuncId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AffGroupHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupHistory](
	[AffId] [int] NOT NULL,
	[MonthDate] [datetime] NOT NULL,
	[GroupId] [int] NOT NULL,
	[ParentAffId] [int] NULL,
	[AllParentAffId] [varchar](max) NULL,
 CONSTRAINT [PK_AffGroupHistory] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData] TEXTIMAGE_ON [AffData]
GO
/****** Object:  Table [dbo].[AffGroupInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupInfo](
	[GroupId] [int] IDENTITY(1000,1) NOT NULL,
	[GroupName] [nvarchar](50) NOT NULL,
	[GroupDesc] [nvarchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[DisplayOrder] [tinyint] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_AffGroupInfo] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffGroupPolicy]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupPolicy](
	[GroupId] [int] NOT NULL,
	[FuncId] [int] NOT NULL,
	[Policy] [tinyint] NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_AffGroupPolicy] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[FuncId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[Affiliate_User]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_User](
	[CustId] [int] IDENTITY(1000000000,1) NOT NULL,
	[PageAccess] [nvarchar](500) NULL,
	[CreateDate] [datetime] NULL,
	[Creator] [int] NULL,
	[GroupId] [int] NULL,
	[Closed] [bit] NULL,
	[LoginCount] [tinyint] NULL,
	[IPLogin] [varchar](20) NULL,
	[LastLogged] [smalldatetime] NULL,
	[On_SessionId] [int] NULL,
	[UserName] [varchar](30) NULL,
	[UserPwd] [varchar](40) NULL,
	[RoleId] [tinyint] NULL,
	[PwdExpiry] [datetime] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
 CONSTRAINT [PK_Affiliate_User] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffiliateCode]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffiliateCode](
	[AffCode] [varchar](20) NOT NULL,
	[AffId] [int] NULL,
 CONSTRAINT [PK_AffiliateCode] PRIMARY KEY CLUSTERED 
(
	[AffCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AffInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffInfo](
	[AffId] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](30) NULL,
	[UserName2] [nvarchar](30) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[GroupId] [int] NULL,
	[Status] [varchar](30) NULL,
	[ApprovedDate] [datetime] NULL,
	[IsClosed] [bit] NULL,
	[Currency] [int] NULL,
	[RegisteredDate] [datetime] NULL,
	[Email] [nvarchar](50) NULL,
	[Password] [varchar](40) NULL,
	[AffType] [tinyint] NULL,
	[IsPageEnabled] [bit] NULL,
	[Level] [tinyint] NULL,
	[IsLocked] [bit] NULL,
	[CasinoJoinedDate] [datetime] NULL,
	[ForceChangePass] [bit] NULL,
	[SecretKey] [varchar](50) NULL,
	[CurrencyName] [nvarchar](50) NULL,
	[CurrencyCode] [varchar](3) NULL,
	[ParentAffId] [int] NULL,
	[AllParentAffId] [varchar](max) NULL,
	[IsSuspended] [bit] NULL,
	[SuspendedDate] [datetime] NULL,
	[ApprovedBy] [int] NULL,
	[DefaultCurrency] [int] NULL,
	[AffCode] [varchar](20) NULL,
	[IsRejected] [bit] NULL,
 CONSTRAINT [PK_AffInfo] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData] TEXTIMAGE_ON [AffData]
GO
/****** Object:  Table [dbo].[AffLoginInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffLoginInfo](
	[AffId] [int] NOT NULL,
	[LoginSessionId] [varchar](30) NOT NULL,
	[LastLoginDate] [datetime] NULL,
	[LastLoginIP] [varchar](50) NULL,
	[FailedLoginCount] [tinyint] NULL,
 CONSTRAINT [PK_AffLoginInfo] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[LoginSessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffMediaChannel]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMediaChannel](
	[AffId] [int] NOT NULL,
	[ChannelCode] [varchar](50) NOT NULL,
	[ChannelName] [nvarchar](200) NULL,
	[IsDeleted] [bit] NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_AffMediaChanel] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[ChannelCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffMediaLink]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMediaLink](
	[AffId] [int] NOT NULL,
	[ChannelCode] [varchar](50) NOT NULL,
	[LanguageCode] [varchar](10) NULL,
	[AffMediaLink] [varchar](500) NOT NULL,
	[IsShow] [bit] NULL
) ON [SettingData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_AffMediaLink]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_AffMediaLink] ON [dbo].[AffMediaLink]
(
	[AffId] ASC,
	[ChannelCode] ASC,
	[LanguageCode] ASC,
	[AffMediaLink] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffMemberPolicy]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMemberPolicy](
	[CustId] [int] NOT NULL,
	[FuncId] [int] NOT NULL,
	[Policy] [tinyint] NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_AffMemberPolicy] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC,
	[FuncId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffPayout]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffPayout](
	[RefId] [bigint] IDENTITY(2000000001,1) NOT NULL,
	[AffId] [int] NULL,
	[Amount] [money] NULL,
	[AffPayout] [money] NULL,
	[AffCurrency] [int] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Status] [varchar](50) NULL,
	[AdminDesc] [nvarchar](300) NULL,
	[AffDesc] [nvarchar](300) NULL,
	[PreferredPayment] [varchar](20) NULL,
	[Player_Username] [varchar](30) NULL,
	[Player_Currency] [int] NULL,
	[Player_CurrencyName] [nvarchar](50) NULL,
	[Player_CurrencyCode] [varchar](3) NULL,
	[Player_CustId] [int] NULL,
	[AffRate] [float] NULL,
 CONSTRAINT [PK_AffPayout] PRIMARY KEY NONCLUSTERED 
(
	[RefId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Index [CIX_AffId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_AffId] ON [dbo].[AffPayout]
(
	[AffId] ASC,
	[TransDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO
/****** Object:  Table [dbo].[AffType]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffType](
	[TypeId] [tinyint] NOT NULL,
	[Name] [nvarchar](100) NULL,
	[Description] [nvarchar](250) NULL,
	[CreatedDate] [datetime] NULL,
	[Creator] [int] NULL,
	[IsShown] [bit] NULL,
 CONSTRAINT [PK_AffType] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[AffUserLoginInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffUserLoginInfo](
	[AffId] [int] NOT NULL,
	[IP] [nvarchar](25) NOT NULL,
	[DeviceInfo] [nvarchar](100) NOT NULL,
	[FailedLoginCount] [tinyint] NULL,
	[LastLoginDate] [datetime] NULL,
	[VerificationCount] [tinyint] NULL,
	[LastVerificationDate] [datetime] NULL,
 CONSTRAINT [PK_AffUserLoginInfo] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[IP] ASC,
	[DeviceInfo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[ClickStatistics]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatistics](
	[ClickId] [bigint] IDENTITY(1,1) NOT NULL,
	[AffId] [int] NOT NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[IP] [varchar](25) NOT NULL,
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
	[LanguageCode] [varchar](10) NULL,
	[SportCode] [varchar](50) NULL,
	[RedirectURL] [nvarchar](256) NULL,
	[Status] [tinyint] NULL,
	[DeviceType] [tinyint] NULL,
	[AffMediaLink] [varchar](500) NULL,
 CONSTRAINT [PK_ClickStatistics] PRIMARY KEY NONCLUSTERED 
(
	[ClickId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_AffId_Date]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_AffId_Date] ON [dbo].[ClickStatistics]
(
	[AffId] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Table [dbo].[ClickStatistics_bk]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatistics_bk](
	[ClickId] [bigint] NOT NULL,
	[AffId] [int] NOT NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[IP] [varchar](25) NOT NULL,
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
	[LanguageCode] [varchar](10) NULL,
	[SportCode] [varchar](50) NULL,
	[RedirectURL] [nvarchar](256) NULL,
	[Status] [tinyint] NULL,
	[DeviceType] [tinyint] NULL,
	[AffMediaLink] [varchar](500) NULL,
 CONSTRAINT [PK_ClickStatistics_bk] PRIMARY KEY NONCLUSTERED 
(
	[ClickId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_Date_AffId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_Date_AffId] ON [dbo].[ClickStatistics_bk]
(
	[Date] ASC,
	[AffId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Table [dbo].[ClickStatisticsSum]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatisticsSum](
	[AffId] [int] NOT NULL,
	[DomainReferrer] [nvarchar](300) NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[LanguageCode] [varchar](10) NOT NULL,
	[SportCode] [varchar](50) NOT NULL,
	[DeviceType] [tinyint] NOT NULL,
	[TotalClick] [int] NULL,
	[UniqueClick] [int] NULL,
	[TotalSignup] [int] NULL,
	[TotalDeposit] [int] NULL,
 CONSTRAINT [PK_ClickStatisticsSum] PRIMARY KEY CLUSTERED 
(
	[Date] ASC,
	[AffId] ASC,
	[DomainReferrer] ASC,
	[SportCode] ASC,
	[LanguageCode] ASC,
	[DeviceType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[CommGroup]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroup](
	[GroupId] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [nvarchar](100) NULL,
	[Description] [nvarchar](100) NULL,
	[Creator] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[IsPrivate] [bit] NULL,
	[IsDeleted] [bit] NULL,
	[SubCommRate] [decimal](9, 8) NULL,
 CONSTRAINT [PK_CommGroup] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[CommGroupHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroupHistory](
	[MonthDate] [datetime] NOT NULL,
	[GroupId] [int] NOT NULL,
	[SubCommRate] [decimal](9, 8) NULL,
 CONSTRAINT [PK_CommGroupHistory] PRIMARY KEY CLUSTERED 
(
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[Deductions]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Deductions](
	[DeductionId] [tinyint] NOT NULL,
	[DeductionName] [varchar](50) NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
	[IsTest] [bit] NULL,
	[IsDeleted] [bit] NULL,
	[DeductedAmount] [money] NULL,
	[IsDeductedPercent] [bit] NULL,
	[Commission] [decimal](9, 8) NULL,
 CONSTRAINT [PK_Deductions] PRIMARY KEY CLUSTERED 
(
	[DeductionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[DeductionSetting]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSetting](
	[GroupId] [int] NOT NULL,
	[DeductionId] [tinyint] NOT NULL,
	[ProductId] [int] NOT NULL,
	[GroupProductId] [int] NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
	[DeductedAmount] [money] NULL,
	[IsDeductedPercent] [bit] NULL,
 CONSTRAINT [PK_DeductionSetting] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[DeductionId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[DeductionSettingHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSettingHistory](
	[GroupId] [int] NOT NULL,
	[MonthDate] [datetime] NOT NULL,
	[DeductionId] [tinyint] NOT NULL,
	[ProductId] [int] NOT NULL,
	[GroupProductId] [int] NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
	[DeductedAmount] [money] NULL,
	[IsDeductedPercent] [bit] NULL,
 CONSTRAINT [PK_DeductionSettingHistory] PRIMARY KEY NONCLUSTERED 
(
	[GroupId] ASC,
	[MonthDate] ASC,
	[DeductionId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Index [CIX_MonthDate_GroupId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_MonthDate_GroupId] ON [dbo].[DeductionSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC,
	[DeductionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Table [dbo].[DomainControl]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DomainControl](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AffDomainId] [int] NOT NULL,
	[LicenseeDomainId] [int] NOT NULL,
	[MarketId] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
	[Status] [bit] NULL,
	[DeviceType] [tinyint] NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_DomainControl] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Index [CIX_AffDomainId_LicenseeDomainId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_AffDomainId_LicenseeDomainId] ON [dbo].[DomainControl]
(
	[AffDomainId] ASC,
	[LicenseeDomainId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Table [dbo].[EmailHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailHistory](
	[MId] [int] IDENTITY(1,1) NOT NULL,
	[Content] [nvarchar](4000) NULL,
	[Sender] [nvarchar](100) NULL,
	[Creator] [int] NULL,
	[AffId] [int] NULL,
	[AffName] [varchar](30) NULL,
	[Email] [nvarchar](50) NULL,
	[Subject] [nvarchar](2000) NULL,
	[CreatedDate] [datetime] NULL,
	[IP] [varchar](25) NULL,
	[Browser] [nvarchar](100) NULL,
	[SessionId] [varchar](200) NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_EmailHistory] PRIMARY KEY CLUSTERED 
(
	[MId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[Exchange]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exchange](
	[ExchangeId] [int] NOT NULL,
	[Code] [varchar](5) NULL,
	[ActualRate] [float] NULL,
	[VND] [float] NULL,
	[EUR] [float] NULL,
	[USD] [float] NULL,
	[CNY] [float] NULL,
	[MYR] [float] NULL,
	[THB] [float] NULL,
	[IDR] [float] NULL,
	[MultipliedBy] [int] NULL,
 CONSTRAINT [PK_Exchange] PRIMARY KEY CLUSTERED 
(
	[ExchangeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[IPv4Addresses]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IPv4Addresses](
	[From] [bigint] NOT NULL,
	[To] [bigint] NOT NULL,
	[Code2] [nchar](2) NOT NULL,
	[Code3] [nchar](3) NOT NULL,
	[Country] [nvarchar](64) NOT NULL
) ON [SettingData]
GO
/****** Object:  Table [dbo].[LandingPage]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LandingPage](
	[PageId] [smallint] IDENTITY(1,1) NOT NULL,
	[PageName] [nvarchar](200) NULL,
	[PageCode] [nvarchar](100) NULL,
	[IsDeleted] [bit] NULL,
 CONSTRAINT [PK_LandingPage] PRIMARY KEY CLUSTERED 
(
	[PageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[LicenseeDomain]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LicenseeDomain](
	[DomainId] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
	[DeviceType] [tinyint] NULL,
	[IsDeleted] [bit] NULL,
	[W3Prefix] [varchar](30) NULL,
	[IsSSL] [bit] NULL,
 CONSTRAINT [PK_LicenseeDomain] PRIMARY KEY CLUSTERED 
(
	[DomainId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[LogAction]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogAction](
	[ActionId] [int] NOT NULL,
	[ActionTypeId] [int] NULL,
	[SPName] [varchar](200) NULL,
	[Description] [nvarchar](4000) NULL,
 CONSTRAINT [PK_LogAction] PRIMARY KEY NONCLUSTERED 
(
	[ActionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_SPName]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_SPName] ON [dbo].[LogAction]
(
	[SPName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO
/****** Object:  Table [dbo].[LogType]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogType](
	[TypeId] [smallint] NOT NULL,
	[TypeName] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,
 CONSTRAINT [PK_LogType] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData]
GO
/****** Object:  Table [dbo].[Market]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Market](
	[MarketId] [nvarchar](10) NOT NULL,
	[MarketName] [nvarchar](50) NULL,
	[MarketNativeName] [nvarchar](50) NULL,
	[ShortedCode] [nvarchar](10) NULL,
	[DisplayName] [nvarchar](50) NULL,
 CONSTRAINT [PK_Market] PRIMARY KEY CLUSTERED 
(
	[MarketId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[MediaGallery]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaGallery](
	[MediaId] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [nvarchar](200) NOT NULL,
	[TargetId] [tinyint] NULL,
	[ImageType] [varchar](10) NULL,
	[Message] [nvarchar](max) NULL,
	[Size] [varchar](20) NULL,
	[Categories] [varchar](2000) NULL,
	[SubCategories] [varchar](2000) NULL,
	[Language] [varchar](100) NULL,
	[Currencies] [varchar](500) NULL,
	[AffTypes] [varchar](20) NULL,
	[DeviceTypes] [varchar](10) NULL,
	[Creator] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_MediaGallery] PRIMARY KEY NONCLUSTERED 
(
	[MediaId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData] TEXTIMAGE_ON [SettingData]
GO
/****** Object:  Table [dbo].[MemberClickDetail]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberClickDetail](
	[CustId] [int] NOT NULL,
	[ClickId] [bigint] NOT NULL,
	[DomainReferrer] [nvarchar](300) NULL,
	[IBCCustId] [int] NULL,
	[LanguageCode] [varchar](10) NULL,
	[SportCode] [varchar](50) NULL,
	[URLRedirect] [nvarchar](300) NULL,
	[URLReferrer] [nvarchar](300) NULL,
	[DeviceType] [tinyint] NULL,
	[AffID] [int] NULL,
	[CreatedDate] [datetime] NULL,
 CONSTRAINT [PK_MemberClickDetail] PRIMARY KEY NONCLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [IX_CreatedDate]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [IX_CreatedDate] ON [dbo].[MemberClickDetail]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Table [dbo].[MemberInfo]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberInfo](
	[CustId] [int] NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[Currency] [int] NULL,
	[ActStatus] [tinyint] NULL,
	[Status] [tinyint] NULL,
	[RegisteredDate] [datetime] NULL,
	[AffId] [int] NOT NULL,
	[IBCCustId] [int] NULL,
	[IBCUserName] [varchar](30) NULL,
	[CreatedDate] [datetime] NULL,
	[IsRemoved] [bit] NULL,
	[Recommend] [int] NULL,
	[ClickId] [bigint] NULL,
	[FirstDepositDate] [datetime] NULL,
	[FirstDepositAmount] [money] NULL,
 CONSTRAINT [PK_MemberInfo] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[MemberRemoval]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberRemoval](
	[CustId] [int] NOT NULL,
	[RemovedDate] [datetime] NOT NULL,
	[RemovedBy] [int] NULL,
	[FromDate] [smalldatetime] NULL,
	[ToDate] [smalldatetime] NULL,
	[IsInclude] [bit] NULL,
 CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC,
	[RemovedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
/****** Object:  Table [dbo].[Messages]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Messages](
	[MessageId] [int] NOT NULL,
	[MessageTypeId] [smallint] NULL,
	[Description] [nvarchar](2000) NULL,
	[MessageContentEN] [nvarchar](2000) NULL,
	[MessageContentCS] [nvarchar](2000) NULL,
	[MessageContentCH] [nvarchar](2000) NULL,
	[MessageContentID] [nvarchar](2000) NULL,
	[MessageContentVN] [nvarchar](2000) NULL,
	[MessageContentTH] [nvarchar](2000) NULL,
	[MessageContentKO] [nvarchar](2000) NULL,
	[MessageContentES] [nvarchar](2000) NULL,
	[MessageContentJP] [nvarchar](2000) NULL,
	[MessageContentHIEN] [nvarchar](2000) NULL,
	[MessageContentENEURO] [nvarchar](2000) NULL,
	[MessageContentMS] [nvarchar](2000) NULL,
	[MessageContentKH] [nvarchar](4000) NULL,
	[MessageContentBN] [nvarchar](4000) NULL,
 CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED 
(
	[MessageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[News]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[News](
	[MsgId] [int] IDENTITY(1,1) NOT NULL,
	[Message_En] [nvarchar](4000) NULL,
	[Message_Cn] [nvarchar](4000) NULL,
	[Message_Tw] [nvarchar](4000) NULL,
	[Message_Es] [nvarchar](4000) NULL,
	[Message_Th] [nvarchar](4000) NULL,
	[Message_Id] [nvarchar](4000) NULL,
	[Message_Vi] [nvarchar](4000) NULL,
	[Message_Kr] [nvarchar](4000) NULL,
	[Message_Jp] [nvarchar](4000) NULL,
	[Creator] [int] NULL,
	[PostedDate] [datetime] NULL,
	[Important] [bit] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
	[Message_Hi] [nvarchar](4000) NULL,
	[Message_Ms] [nvarchar](4000) NULL,
	[Message_Kh] [nvarchar](4000) NULL,
	[Message_Bn] [nvarchar](4000) NULL,
 CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED 
(
	[MsgId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[On_User]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[On_User](
	[On_UserId] [int] IDENTITY(1,1) NOT NULL,
	[On_SessionId] [int] NOT NULL,
	[CustId] [int] NULL,
	[Reload_Time] [datetime] NULL,
	[ServerId] [int] NULL,
	[IP] [nvarchar](20) NULL,
	[IsKickedOut] [bit] NULL,
	[SubAccId] [int] NULL,
	[NetSessionId] [varchar](30) NULL,
	[Country] [smallint] NULL,
	[MachineIP] [int] NULL,
	[DomainId] [int] NULL,
 CONSTRAINT [PK_On_User] PRIMARY KEY CLUSTERED 
(
	[On_UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[Products]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products](
	[ProductId] [int] NOT NULL,
	[ProductName] [varchar](100) NOT NULL,
	[ProductPrefix] [varchar](10) NULL,
	[IsIBC] [bit] NULL,
	[Enabled] [bit] NULL,
	[IsTest] [bit] NULL,
	[EndOfSupportDate] [smalldatetime] NULL,
	[ReleasedDate] [smalldatetime] NULL,
	[RefProductId] [int] NULL,
	[DataSource] [varchar](100) NULL,
	[IsP2P] [bit] NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[rptAffCommission]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffCommission](
	[MonthDate] [smalldatetime] NOT NULL,
	[AffId] [int] NOT NULL,
	[GroupId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[Deposit] [money] NULL,
	[Withdrawal] [money] NULL,
	[Bonus] [money] NULL,
	[Adjustment] [money] NULL,
	[Turnover] [money] NULL,
	[Winloss] [money] NULL,
	[GrossWinloss] [money] NULL,
	[NetWinloss] [money] NULL,
	[QMTurnover] [money] NULL,
	[ActivePlayer] [int] NULL,
	[QualifiedMember] [int] NULL,
	[CommissionRate] [decimal](9, 8) NULL,
	[Rebate] [money] NULL,
	[Revenue] [money] NULL,
	[P2PFee] [money] NULL,
	[PlatFormFee] [money] NULL,
	[OperationalFee] [money] NULL,
	[DepositFee] [money] NULL,
	[WithdrawalFee] [money] NULL,
 CONSTRAINT [PK_rptAffCommission] PRIMARY KEY CLUSTERED 
(
	[MonthDate] ASC,
	[AffId] ASC,
	[GroupId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[rptAffCommissionDetail]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffCommissionDetail](
	[MonthDate] [smalldatetime] NOT NULL,
	[AffId] [int] NOT NULL,
	[GroupId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[Deposit] [money] NULL,
	[Withdrawal] [money] NULL,
	[Bonus] [money] NULL,
	[Adjustment] [money] NULL,
	[Turnover] [money] NULL,
	[Winloss] [money] NULL,
	[GrossWinloss] [money] NULL,
	[NetWinloss] [money] NULL,
	[QMTurnover] [money] NULL,
	[ActivePlayer] [int] NULL,
	[QualifiedMember] [int] NULL,
	[CommissionRate] [decimal](9, 8) NULL,
	[Rebate] [money] NULL,
	[Revenue] [money] NULL,
	[P2PFee] [money] NULL,
	[PlatFormFee] [money] NULL,
	[OperationalFee] [money] NULL,
	[DepositFee] [money] NULL,
	[WithdrawalFee] [money] NULL,
	[GroupProductId] [tinyint] NOT NULL,
 CONSTRAINT [PK_rptAffCommissionDetail] PRIMARY KEY CLUSTERED 
(
	[MonthDate] ASC,
	[AffId] ASC,
	[GroupId] ASC,
	[ProductId] ASC,
	[GroupProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO

/****** Object:  Table [dbo].[rptAffMonthly]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffMonthly](
	[MonthDate] [smalldatetime] NOT NULL,
	[AffId] [int] NOT NULL,
	[GroupId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[Turnover] [money] NULL,
	[Winloss] [money] NULL,
	[Revenue] [money] NULL,
 CONSTRAINT [PK_rptAffMonthly] PRIMARY KEY CLUSTERED 
(
	[MonthDate] ASC,
	[AffId] ASC,
	[GroupId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[rptMemberDaily]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptMemberDaily](
	[WinlostDate] [smalldatetime] NOT NULL,
	[AffId] [int] NULL,
	[CustId] [int] NOT NULL,
	[Currency] [int] NULL,
	[ExRate] [float] NULL,
	[AffExRate] [float] NULL,
	[ProductId] [int] NOT NULL,
	[Deposit] [money] NULL,
	[Withdrawal] [money] NULL,
	[Bonus] [money] NULL,
	[Adjustment] [money] NULL,
	[Turnover] [money] NULL,
	[Winloss] [money] NULL,
	[Rebate] [money] NULL,
	[Revenue] [money] NULL,
	[ProgressiveBet] [money] NULL,
	[ProgressiveWin] [money] NULL,
 CONSTRAINT [PK_rptMemberDaily] PRIMARY KEY NONCLUSTERED 
(
	[WinlostDate] ASC,
	[CustId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_WinlostDate_AffId_ProductId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_WinlostDate_AffId_ProductId] ON [dbo].[rptMemberDaily]
(
	[WinlostDate] ASC,
	[AffId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[StraightSetting]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StraightSetting](
	[GroupId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[GroupProductId] [int] NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
	[Commission] [decimal](9, 8) NULL,
 CONSTRAINT [PK_StraightSetting] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[StraightSettingHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StraightSettingHistory](
	[GroupId] [int] NOT NULL,
	[MonthDate] [datetime] NOT NULL,
	[ProductId] [int] NOT NULL,
	[GroupProductId] [int] NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
	[Commission] [decimal](9, 8) NULL,
 CONSTRAINT [PK_StraightSettingHistory] PRIMARY KEY NONCLUSTERED 
(
	[GroupId] ASC,
	[MonthDate] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Index [CIX_StraightSettingHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_StraightSettingHistory] ON [dbo].[StraightSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Table [dbo].[SubAffDomain]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubAffDomain](
	[DomainId] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
	[IsDeleted] [bit] NULL,
	[IsSSL] [bit] NULL,
 CONSTRAINT [PK_SubAffDomain] PRIMARY KEY CLUSTERED 
(
	[DomainId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[TierSetting]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TierSetting](
	[GroupId] [int] NOT NULL,
	[TierId] [int] NOT NULL,
	[MinAmount] [money] NULL,
	[MaxAmount] [money] NULL,
	[MinAM] [int] NULL,
	[MaxAM] [int] NULL,
	[Commission] [decimal](9, 8) NULL,
	[GroupProductId] [tinyint] NOT NULL,
	[IsActivePlayerSum] [bit] NULL,
 CONSTRAINT [PK_TierSetting] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[GroupProductId] ASC,
	[TierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[TierSettingHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TierSettingHistory](
	[GroupId] [int] NOT NULL,
	[MonthDate] [datetime] NOT NULL,
	[TierId] [int] NOT NULL,
	[MinAmount] [money] NULL,
	[MaxAmount] [money] NULL,
	[MinAM] [int] NULL,
	[MaxAM] [int] NULL,
	[Commission] [decimal](9, 8) NULL,
	[GroupProductId] [tinyint] NOT NULL,
	[IsActivePlayerSum] [bit] NULL,
 CONSTRAINT [PK_TierSettingHistory] PRIMARY KEY NONCLUSTERED 
(
	[GroupId] ASC,
	[MonthDate] ASC,
	[GroupProductId] ASC,
	[TierId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Index [CIX_MonthDate_GroupId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_MonthDate_GroupId] ON [dbo].[TierSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Table [dbo].[TransferBalanceHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransferBalanceHistory](
	[TransId] [bigint] IDENTITY(1000,1) NOT NULL,
	[TransTime] [datetime] NULL,
	[TransDate] [datetime] NULL,
	[Status] [varchar](20) NULL,
	[AffId] [int] NULL,
	[AffUserName] [varchar](50) NULL,
	[Player_CustId] [int] NULL,
	[Player_UserName] [varchar](50) NULL,
	[Player_Currency] [int] NULL,
	[Player_CurrencyCode] [varchar](3) NULL,
	[CustId] [int] NULL,
	[UserName] [varchar](50) NULL,
	[Currency] [int] NULL,
	[CurrencyCode] [varchar](3) NULL,
	[Amount] [money] NULL,
	[ExRate] [float] NULL,
	[LastSyncTime] [datetime] NULL,
	[SyncCount] [tinyint] NULL,
	[SyncLog] [varchar](300) NULL,
 CONSTRAINT [PK_TransferBalanceHistory] PRIMARY KEY NONCLUSTERED 
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_TransferBalanceHistory]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_TransferBalanceHistory] ON [dbo].[TransferBalanceHistory]
(
	[TransDate] ASC,
	[AffId] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Table [dbo].[TransType]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransType](
	[TypeId] [smallint] NOT NULL,
	[TypeName] [nvarchar](50) NULL,
	[TypeDesc] [nvarchar](50) NULL,
 CONSTRAINT [PK_TransType] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[UserLog_RunSP_Detail]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserLog_RunSP_Detail](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[LogTypeId] [int] NULL,
	[LogActionId] [int] NULL,
	[SPName] [varchar](200) NULL,
	[UserId] [int] NULL,
	[AffId] [int] NULL,
	[LogDate] [datetime] NOT NULL,
	[OldData] [nvarchar](max) NULL,
	[NewData] [nvarchar](max) NULL,
	[IP] [varchar](50) NULL,
	[Language] [varchar](20) NULL,
	[IsWebCall] [bit] NULL,
 CONSTRAINT [PK_UserLog_RunSP_Detail] PRIMARY KEY NONCLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData] TEXTIMAGE_ON [LogData]
GO
/****** Object:  Index [CIX_LogActionId_LogDate]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE CLUSTERED INDEX [CIX_LogActionId_LogDate] ON [dbo].[UserLog_RunSP_Detail]
(
	[LogActionId] ASC,
	[LogDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO
/****** Object:  Table [dbo].[Username_AutoIncrement]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Username_AutoIncrement](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PrefixName] [nvarchar](50) NULL,
	[SubfixName] [bigint] NULL,
 CONSTRAINT [PK_Username_AutoIncrement] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Index [IX_TransDate]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_TransDate] ON [dbo].[AffPayout]
(
	[TransDate] ASC
)
INCLUDE([Amount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO
/****** Object:  Index [IX_TransDate]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_TransDate] ON [dbo].[AffTrans]
(
	[TransDate] ASC
)
INCLUDE([Amount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO
/****** Object:  Index [IX_AffId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_AffId] ON [dbo].[MemberClickDetail]
(
	[AffID] ASC
)
INCLUDE([LanguageCode],[SportCode],[DeviceType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Index [IX_AffId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_AffId] ON [dbo].[MemberInfo]
(
	[AffId] ASC,
	[IBCCustId] ASC
)
INCLUDE([UserName],[IBCUserName],[Currency],[FirstName],[LastName],[Email],[RegisteredDate],[CreatedDate],[IsRemoved]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO
/****** Object:  Index [Ix_CustId_FromDate_ToDate]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [Ix_CustId_FromDate_ToDate] ON [dbo].[MemberRemoval]
(
	[CustId] ASC,
	[FromDate] ASC,
	[ToDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
GO
/****** Object:  Index [IX_AffId_GroupId_ProductId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_AffId_GroupId_ProductId] ON [dbo].[rptAffCommission]
(
	[AffId] ASC,
	[GroupId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Index [IX_AffId_ProductId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_AffId_ProductId] ON [dbo].[rptMemberDaily]
(
	[AffId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss],[AffExRate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_SName]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_SName] ON [dbo].[SystemSettings]
(
	[SName] ASC
)
INCLUDE([SValue]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
/****** Object:  Index [IX_UserId_LogActionId]    Script Date: 1/8/2024 12:01:16 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserId_LogActionId] ON [dbo].[UserLog_RunSP_Detail]
(
	[UserId] ASC,
	[LogActionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO
ALTER TABLE [dbo].[AdminNotes] ADD  CONSTRAINT [DF_Affiliate_Note_UpdateDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
ALTER TABLE [dbo].[AffDetail] ADD  CONSTRAINT [DF_AffDetail_DisabledTransfer]  DEFAULT ((1)) FOR [DisabledTransfer]
GO
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffDomain] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_IsSSL]  DEFAULT ((0)) FOR [IsSSL]
GO
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_DisplayOrder]  DEFAULT ((7)) FOR [DisplayOrder]
GO
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_AffGroupInfo_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_AffGroupInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_AffGroupPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_AffGroupPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsClosed]  DEFAULT ((0)) FOR [IsClosed]
GO
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsRejected]  DEFAULT ((0)) FOR [IsRejected]
GO
ALTER TABLE [dbo].[AffMediaChannel] ADD  CONSTRAINT [DF_AffMediaChanel_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[AffMediaChannel] ADD  CONSTRAINT [DF_AffMediaChanel_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[AffMediaLink] ADD  CONSTRAINT [DF_AffMediaLink_IsShow]  DEFAULT ((1)) FOR [IsShow]
GO
ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_AffMemberPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_AffMemberPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffType] ADD  CONSTRAINT [DF_AffType_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[AffType] ADD  CONSTRAINT [DF_AffType_IsShown]  DEFAULT ((0)) FOR [IsShown]
GO
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_DeviceType]  DEFAULT ((0)) FOR [DeviceType]
GO
ALTER TABLE [dbo].[CommGroup] ADD  CONSTRAINT [DF_CommGroup_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[CommGroup] ADD  CONSTRAINT [DF_CommGroup_IsPrivate]  DEFAULT ((0)) FOR [IsPrivate]
GO
ALTER TABLE [dbo].[CommGroup] ADD  CONSTRAINT [DF_CommGroup_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_IsTest]  DEFAULT ((0)) FOR [IsTest]
GO
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_Commission]  DEFAULT ((0)) FOR [Commission]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_DeviceType]  DEFAULT ((0)) FOR [DeviceType]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_EmailHistory_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_EmailHistory_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Exchange] ADD  CONSTRAINT [DF_Exchange_MultipliedBy]  DEFAULT ((0)) FOR [MultipliedBy]
GO
ALTER TABLE [dbo].[LandingPage] ADD  CONSTRAINT [DF_LandingPage_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[LicenseeDomain] ADD  CONSTRAINT [DF_LicenseeDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[LicenseeDomain] ADD  CONSTRAINT [DF_LicenseeDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[LicenseeDomain] ADD  CONSTRAINT [DF_LicenseeDomain_DeviceType]  DEFAULT ((0)) FOR [DeviceType]
GO
ALTER TABLE [dbo].[LicenseeDomain] ADD  CONSTRAINT [DF_LicenseeDomain_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[LicenseeDomain] ADD  CONSTRAINT [DF_LicenseeDomain_IsSSL]  DEFAULT ((0)) FOR [IsSSL]
GO
ALTER TABLE [dbo].[MediaGallery] ADD  CONSTRAINT [DF_MediaGallery_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_IsRemoved]  DEFAULT ((0)) FOR [IsRemoved]
GO
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_ClickId]  DEFAULT ((0)) FOR [ClickId]
GO
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_News_Important]  DEFAULT ((0)) FOR [Important]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_IsTest]  DEFAULT ((0)) FOR [IsTest]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_IsP2P]  DEFAULT ((0)) FOR [IsP2P]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_IsSSL]  DEFAULT ((0)) FOR [IsSSL]
GO
ALTER TABLE [dbo].[UserLog_RunSP_Detail] ADD  CONSTRAINT [DF_UserLog_RunSP_Detail_LogDate]  DEFAULT (getdate()) FOR [LogDate]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Admin_Affiliate_Approved]    Script Date: 1/8/2024 12:01:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
USE [master]
GO
ALTER DATABASE [Affiliate_YashBet] SET  READ_WRITE 
GO
