USE [Affiliate_Licensee]
GO
/****** Object:  Table [dbo].[MemberDailyRemoved]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberDailyRemoved](
	[UserName] [varchar](30) NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[ProductID] [tinyint] NOT NULL,
	[AffID] [int] NULL,
	[IBCCustID] [int] NULL,
	[Currency] [smallint] NOT NULL,
	[AffCurrency] [smallint] NULL,
	[AffExRate] [float] NULL,
	[SysCurrency] [smallint] NULL,
	[SysExRate] [float] NULL,
	[Deposit] [money] NOT NULL,
	[Withdrawal] [money] NOT NULL,
	[Bonus] [money] NOT NULL,
	[Adjustment] [money] NOT NULL,
	[Turnover] [money] NOT NULL,
	[Outstanding] [money] NOT NULL,
	[Winlost] [money] NOT NULL,
	[DrawGame] [money] NOT NULL,
	[PSP] [money] NOT NULL,
	[Marketing] [money] NOT NULL,
	[MemWinlostFake] [money] NULL,
	[MemOddsFee] [money] NULL,
	[MemPLayTechFee] [money] NULL,
 CONSTRAINT [PK_MemberDailyRemoved] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC,
	[WinlostDate] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportData]
) ON [ReportData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserLog_RunSP]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_RunSP](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[AffID] [int] NULL,
	[Creator] [int] NULL,
	[SPName] [varchar](50) NULL,
	[Details] [varchar](4000) NULL,
	[LoggedDate] [datetime] NULL,
	[IsAdmin] [bit] NULL,
	[IP] [varchar](25) NULL
) ON [UserLogData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UserLog_IISErr]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_IISErr](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[LoggedDate] [smalldatetime] NULL,
	[Page] [varchar](50) NULL,
	[Function] [tinyint] NULL,
	[ErrMessage] [nvarchar](4000) NULL
) ON [UserLogData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransType]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransType](
	[TypeID] [smallint] NOT NULL,
	[TypeName] [nvarchar](50) NULL,
	[TypeDesc] [nvarchar](50) NULL,
 CONSTRAINT [PK_TransType] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[TrackingCode]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrackingCode](
	[TrackingID] [int] IDENTITY(1,1) NOT NULL,
	[AffID] [int] NOT NULL,
	[TrackingCode] [varchar](20) NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[IP] [varchar](23) NOT NULL,
 CONSTRAINT [PK_TrackingCode] PRIMARY KEY CLUSTERED 
(
	[TrackingID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TaskManager]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TaskManager](
	[TaskID] [smallint] NOT NULL,
	[TaskName] [varchar](100) NULL,
	[Description] [varchar](100) NULL,
	[Creator] [smallint] NULL,
	[LastRun] [datetime] NULL,
	[Priority] [smallint] NULL,
	[StartedDate] [datetime] NULL,
	[Schedule] [varchar](255) NULL,
	[Command] [varchar](255) NULL,
	[BeginTime] [varchar](50) NULL,
	[IntervalTime] [int] NULL,
 CONSTRAINT [PK_TaskManager] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TaskLog]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TaskLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[TaskID] [smallint] NULL,
	[RunDate] [datetime] NULL,
	[Status] [varchar](50) NULL,
	[CompletedDate] [datetime] NULL,
 CONSTRAINT [PK_TaskLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [StatData]
) ON [StatData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SystemSettings]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[SID] [int] IDENTITY(1,1) NOT NULL,
	[Type] [varchar](50) NULL,
	[SName] [varchar](50) NULL,
	[SValue] [nvarchar](max) NULL,
	[Description] [varchar](100) NULL,
	[Environment] [varchar](50) NULL,
 CONSTRAINT [PK_SystemSettings] PRIMARY KEY CLUSTERED 
(
	[SID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RefResources2]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RefResources2](
	[RefID] [varchar](50) NULL,
	[LanguageCode] [varchar](8) NULL,
	[ResourceKey] [varchar](50) NULL,
	[ResourceValue] [nvarchar](max) NULL,
	[Description] [nvarchar](100) NULL
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RefResources]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RefResources](
	[ResourceID] [uniqueidentifier] NOT NULL,
	[RefID] [varchar](50) NULL,
	[LanguageCode] [varchar](8) NULL,
	[ResourceKey] [varchar](50) NULL,
	[ResourceValue] [nvarchar](max) NULL,
	[Description] [nvarchar](100) NULL,
 CONSTRAINT [PK_RefResources] PRIMARY KEY CLUSTERED 
(
	[ResourceID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ref]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Ref](
	[RefName] [varchar](10) NOT NULL,
	[RefNo] [bigint] NULL,
 CONSTRAINT [PK_Ref] PRIMARY KEY CLUSTERED 
(
	[RefName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Product]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Product](
	[ProductID] [tinyint] NOT NULL,
	[ProductName] [varchar](50) NULL,
	[API_ProductID] [int] NULL,
	[Creator] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[Description] [varchar](100) NULL,
	[BettypeList] [varchar](255) NULL,
	[QMTurnOver] [money] NULL,
	[QMDeposit] [money] NULL,
	[ReportColumns] [varchar](500) NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[On_User]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[On_User](
	[on_userid] [int] IDENTITY(1,1) NOT NULL,
	[on_sessionid] [int] NOT NULL,
	[custid] [int] NULL,
	[reload_time] [smalldatetime] NULL,
	[ServerID] [int] NULL,
	[IP] [nvarchar](15) NULL,
	[iskickedout] [bit] NULL,
	[subaccid] [int] NULL,
	[NetSessionID] [varchar](30) NULL,
	[Country] [smallint] NULL,
	[MachineIP] [int] NULL,
	[domainID] [int] NULL,
 CONSTRAINT [PK_On_User] PRIMARY KEY CLUSTERED 
(
	[on_userid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[News]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[News](
	[MsgID] [int] IDENTITY(1,1) NOT NULL,
	[Message_En] [nvarchar](4000) NULL,
	[Message_Cn] [nvarchar](4000) NULL,
	[Message_Tw] [nvarchar](4000) NULL,
	[Message_Es] [nvarchar](4000) NULL,
	[Message_Th] [nvarchar](4000) NULL,
	[Message_Id] [nvarchar](4000) NULL,
	[Message_Vi] [nvarchar](4000) NULL,
	[Creator] [int] NULL,
	[PostedDate] [datetime] NULL,
	[Important] [bit] NOT NULL,
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED 
(
	[MsgID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[MemberRemoval]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberRemoval](
	[UserName] [varchar](30) NOT NULL,
	[RemovedDate] [datetime] NULL,
	[RemovedBy] [int] NULL,
 CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MemberInfo]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberInfo](
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
 CONSTRAINT [PK_MemberInfo] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MemberDomain]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberDomain](
	[DomainID] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_MemberDomain] PRIMARY KEY CLUSTERED 
(
	[DomainID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[ClickStatistics]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClickStatistics](
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
	[ClickCount] [int] NULL,
 CONSTRAINT [PK_ClickStatistics] PRIMARY KEY CLUSTERED 
(
	[ClickID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [StatData]
) ON [StatData]
GO
SET ANSI_PADDING OFF
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0: not 
signup; 1: signup; 2: deposited' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ClickStatistics', @level2type=N'COLUMN',@level2name=N'Status'
GO
/****** Object:  Table [dbo].[Branch]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Branch](
	[BranchID] [smallint] NOT NULL,
	[BranchName] [varchar](50) NOT NULL,
	[CountryID] [varchar](8) NOT NULL,
	[Address] [varchar](255) NOT NULL,
	[BankAccount] [varchar](100) NULL,
	[BankAccountName] [varchar](100) NULL,
	[Creator] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Description] [varchar](100) NULL,
 CONSTRAINT [PK_Market] PRIMARY KEY CLUSTERED 
(
	[BranchID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BannerTypes]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BannerTypes](
	[TypeID] [smallint] IDENTITY(1,1) NOT NULL,
	[Type] [varchar](50) NULL,
	[Value] [varchar](50) NULL,
	[DisplayOrder] [tinyint] NULL,
	[ParentID] [smallint] NULL,
 CONSTRAINT [PK_BannerTypes] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Banners]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Banners](
	[BannerID] [int] IDENTITY(1,1) NOT NULL,
	[Category] [smallint] NULL,
	[Language] [varchar](8) NULL,
	[ImageType] [smallint] NULL,
	[Size] [smallint] NULL,
	[LastUpdate] [datetime] NULL,
	[Currency] [smallint] NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[Creator] [int] NULL,
	[Content] [nvarchar](max) NULL,
	[Type] [tinyint] NULL,
	[Version] [int] NULL,
	[TotalRequest] [bigint] NULL,
	[LastRequest] [datetime] NULL,
 CONSTRAINT [PK_Banners] PRIMARY KEY CLUSTERED 
(
	[BannerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BankTrans]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BankTrans](
	[TransID] [int] NOT NULL,
	[CustID] [int] NULL,
	[Bettype] [smallint] NULL,
	[TransDate] [datetime] NULL,
	[Remark] [nvarchar](300) NULL,
	[CreditAffected] [money] NULL,
	[AffTransFee] [money] NULL,
	[OurTransFee] [money] NULL,
	[PreferredPayment] [varchar](20) NULL,
	[Player_Username] [varchar](30) NULL,
	[Neteller_AccountID] [varchar](50) NULL,
	[Moneybookers_Email] [varchar](50) NULL,
	[Wire_BankName] [varchar](100) NULL,
	[Wire_BankAddress] [varchar](200) NULL,
	[Wire_SwiftCode] [varchar](20) NULL,
	[Wire_AccountName] [varchar](100) NULL,
	[Wire_AccountNo] [varchar](50) NULL,
	[Cheque_FullName] [varchar](200) NULL,
	[Cheque_Address] [varchar](200) NULL,
	[Cheque_City] [varchar](50) NULL,
	[Cheque_State] [varchar](50) NULL,
	[Cheque_Postal] [varchar](50) NULL,
	[Cheque_Country] [varchar](50) NULL,
	[CompletedDate] [datetime] NULL,
 CONSTRAINT [PK_BankTrans] PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffType]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffType](
	[TypeID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[Description] [varchar](100) NULL,
	[CreatedDate] [datetime] NULL,
	[Creator] [smallint] NULL,
 CONSTRAINT [PK_AffType] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffTrans]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffTrans](
	[TransID] [bigint] IDENTITY(100000,1) NOT NULL,
	[AffID] [int] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Amount] [money] NULL,
	[Status] [nvarchar](50) NULL,
	[Description] [nvarchar](300) NULL,
	[Creator] [int] NULL,
	[AffCurrency] [smallint] NULL,
	[SysCurrency] [smallint] NULL,
	[SysExRate] [float] NULL,
	[TransType] [int] NULL,
	[RefID] [bigint] NULL,
 CONSTRAINT [PK_AffTrans] PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]
GO
/****** Object:  Table [dbo].[AffPayout]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffPayout](
	[RefID] [bigint] IDENTITY(2000000001,1) NOT NULL,
	[AffID] [int] NULL,
	[IBCCustID] [int] NULL,
	[UserName] [varchar](30) NULL,
	[IBCUserName] [varchar](30) NULL,
	[AffCurrency] [smallint] NULL,
	[Amount] [money] NULL,
	[MemberCurrency] [smallint] NULL,
	[MemberExRate] [float] NULL,
	[AffPayout] [money] NULL,
	[SysCurrency] [smallint] NULL,
	[SysExRate] [float] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[AdminDesc] [nvarchar](300) NULL,
	[AffDesc] [nvarchar](300) NULL,
	[IBCRefNo] [bigint] NULL,
	[IBCTransId] [bigint] NULL,
 CONSTRAINT [PK_AffPayout] PRIMARY KEY CLUSTERED 
(
	[RefID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffMemberPolicy]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMemberPolicy](
	[CustID] [int] NOT NULL,
	[FuncID] [int] NOT NULL,
	[Policy] [tinyint] NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NOT NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_Aff_MemberPolicy] PRIMARY KEY CLUSTERED 
(
	[CustID] ASC,
	[FuncID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [AccInfoData]
) ON [AccInfoData]
GO
/****** Object:  Table [dbo].[AffInfo]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffInfo](
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
 CONSTRAINT [PK_AffInfo] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffGroupPolicy]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupPolicy](
	[GroupID] [int] NOT NULL,
	[FuncID] [int] NOT NULL,
	[Policy] [tinyint] NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_Aff_GroupPolicy] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[FuncID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 85) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[AffGroupInfo]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffGroupInfo](
	[GroupID] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [nvarchar](50) NOT NULL,
	[GroupDesc] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[DisplayOrder] [tinyint] NULL,
	[Creator] [int] NULL,
	[System] [varchar](50) NULL,
 CONSTRAINT [PK_Aff_GroupInfo] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffGroupHistory]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupHistory](
	[AffID] [int] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[GroupID] [int] NOT NULL,
 CONSTRAINT [PK_AffGroupHistory] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[MonthDate] ASC,
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[AffFunctionInfo]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffFunctionInfo](
	[FuncID] [int] IDENTITY(1,1) NOT NULL,
	[FuncName] [nvarchar](50) NULL,
	[FuncNote] [nvarchar](2000) NULL,
	[FuncDesc] [nvarchar](50) NULL,
	[FuncRender] [tinyint] NULL,
	[CreateDate] [datetime] NOT NULL,
	[ModifyDate] [datetime] NOT NULL,
	[DisplayOrder] [tinyint] NULL,
	[Creator] [int] NULL,
	[ParentID] [int] NULL,
	[Filenames] [varchar](2000) NULL,
	[System] [varchar](50) NULL,
 CONSTRAINT [PK_AFF_FunctionInfo] PRIMARY KEY CLUSTERED 
(
	[FuncID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffDomainControl]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDomainControl](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AffDomainID] [int] NOT NULL,
	[MemberDomainID] [int] NOT NULL,
	[CountryID] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
	[Status] [bit] NULL,
 CONSTRAINT [PK_AffDomainControl] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[AffDomain]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDomain](
	[DomainID] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL,
	[ModifyDate] [datetime] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_AffDomain] PRIMARY KEY CLUSTERED 
(
	[DomainID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[AffDetail]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffDetail](
	[AffID] [int] NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[CountryID] [varchar](8) NULL,
	[SiteURL] [varchar](100) NOT NULL,
	[MoreSiteURLs] [varchar](1000) NULL,
	[PreferredLanguage] [varchar](8) NULL,
	[Gender] [bit] NULL,
	[Address] [nvarchar](80) NULL,
	[Postal] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[State] [nvarchar](50) NULL,
	[Phone] [varchar](50) NULL,
	[MobilePhone] [varchar](50) NULL,
	[Fax] [varchar](50) NULL,
	[Question] [nvarchar](300) NULL,
	[Answer] [nvarchar](300) NULL,
	[PreferredPayment] [varchar](20) NULL,
	[Player_IBCCustID] [int] NULL,
	[Player_Username] [varchar](30) NULL,
	[Neteller_AccountID] [varchar](50) NULL,
	[Moneybookers_Email] [nvarchar](50) NULL,
	[Wire_BankName] [nvarchar](100) NULL,
	[Wire_BankAddress] [nvarchar](200) NULL,
	[Wire_SwiftCode] [nvarchar](50) NULL,
	[Wire_AccountName] [nvarchar](100) NULL,
	[Wire_AccountNo] [varchar](50) NULL,
	[Cheque_FullName] [nvarchar](200) NULL,
	[Cheque_Address] [nvarchar](200) NULL,
	[Cheque_City] [nvarchar](50) NULL,
	[Cheque_State] [nvarchar](50) NULL,
	[Cheque_Postal] [nvarchar](50) NULL,
	[Cheque_Country] [nvarchar](50) NULL,
	[BonusCode] [varchar](20) NULL,
	[LastLoginDate] [smalldatetime] NULL,
	[LastLoginIP] [nvarchar](20) NULL,
	[LoginCount] [tinyint] NULL,
	[ValidCode] [nvarchar](11) NULL,
	[CodeExpiry] [datetime] NULL,
	[MailOption] [bit] NULL,
	[NoSiteDesc] [nvarchar](1000) NULL,
	[Player_Currency] [varchar](50) NULL,
 CONSTRAINT [PK_AffDetail] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AffDailySummary]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDailySummary](
	[AffID] [int] NOT NULL,
	[Winlostdate] [smalldatetime] NOT NULL,
	[ProductID] [smallint] NOT NULL,
	[AffCurrency] [smallint] NULL,
	[SysCurrency] [smallint] NULL,
	[MemDeposit] [money] NULL,
	[MemWithdrawal] [money] NULL,
	[MemTurnover] [money] NULL,
	[MemBonus] [money] NULL,
	[MemAdjustment] [money] NULL,
	[MemMarketing] [money] NULL,
	[MemPSP] [money] NULL,
	[MemWinlost] [money] NULL,
	[AffWinlost] [money] NULL,
	[HouseWinlost] [money] NULL,
	[AffNetWinlost] [money] NULL,
	[HouseNetWinlost] [money] NULL,
	[MemOddsFee] [money] NULL,
	[MemDeposit_aff] [money] NULL,
	[MemWithdrawal_aff] [money] NULL,
	[MemTurnover_aff] [money] NULL,
	[MemBonus_aff] [money] NULL,
	[MemAdjustment_aff] [money] NULL,
	[MemMarketing_aff] [money] NULL,
	[MemPSP_aff] [money] NULL,
	[MemWinlost_aff] [money] NULL,
	[AffWinlost_aff] [money] NULL,
	[HouseWinlost_aff] [money] NULL,
	[AffNetWinlost_aff] [money] NULL,
	[HouseNetWinlost_aff] [money] NULL,
	[MemOddsFee_aff] [money] NULL,
	[MemWinlostFake_aff] [money] NULL,
	[MemPLayTechFee] [money] NULL,
	[MemPLayTechFee_aff] [money] NULL,
	[MemWinlostFake] [money] NULL,
 CONSTRAINT [PK_AffDailySummary] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[Winlostdate] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[AffDaily]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDaily](
	[AffID] [int] NOT NULL,
	[MemCurrency] [smallint] NOT NULL,
	[Winlostdate] [smalldatetime] NOT NULL,
	[ProductID] [smallint] NOT NULL,
	[AffCurrency] [smallint] NULL,
	[AffExRate] [float] NULL,
	[SysCurrency] [smallint] NULL,
	[SysExRate] [float] NULL,
	[MemDeposit] [money] NULL,
	[MemWithdrawal] [money] NULL,
	[MemTurnover] [money] NULL,
	[MemBonus] [money] NULL,
	[MemAdjustment] [money] NULL,
	[MemMarketing] [money] NULL,
	[MemPSP] [money] NULL,
	[MemWinlost] [money] NULL,
	[AffWinlost] [money] NULL,
	[HouseWinlost] [money] NULL,
	[AffNetWinlost] [money] NULL,
	[HouseNetWinlost] [money] NULL,
	[MemWinlostFake] [money] NULL,
	[MemOddsFee] [money] NULL,
	[MemPLayTechFee] [money] NULL,
 CONSTRAINT [PK_AffDaily] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[MemCurrency] ASC,
	[Winlostdate] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Table [dbo].[AffCommission]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffCommission](
	[RefID] [bigint] IDENTITY(1000000001,1) NOT NULL,
	[RelNo] [int] NULL,
	[AffID] [int] NOT NULL,
	[GroupID] [int] NOT NULL,
	[ProductID] [tinyint] NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[AffCurrency] [smallint] NULL,
	[SysCurrency] [smallint] NULL,
	[QualifiedMember] [int] NULL,
	[ActivePlayer] [int] NULL,
	[Commission] [decimal](9, 8) NULL,
	[HasBonus] [bit] NULL,
	[HasAdjustment] [bit] NULL,
	[HasMarketing] [bit] NULL,
	[HasPSP] [bit] NULL,
	[HasOddsFee] [bit] NULL,
	[Status] [nvarchar](50) NULL,
	[AffWinlost] [money] NULL,
	[MemberWinlost] [money] NULL,
	[MemberBonus] [money] NULL,
	[MemberAdjustment] [money] NULL,
	[MemberPSP] [money] NULL,
	[MemberSum] [money] NULL,
	[MemberTurnover] [money] NULL,
	[MemberDeposit] [money] NULL,
	[Marketing] [money] NULL,
	[MemOddsFee] [money] NULL,
	[AffWinlost_aff] [money] NULL,
	[MemberWinlost_aff] [money] NULL,
	[MemberBonus_aff] [money] NULL,
	[MemberAdjustment_aff] [money] NULL,
	[MemberPSP_aff] [money] NULL,
	[MemberSum_aff] [money] NULL,
	[MemberTurnover_aff] [money] NULL,
	[MemberDeposit_aff] [money] NULL,
	[Marketing_aff] [money] NULL,
	[MemOddsFee_aff] [money] NULL,
 CONSTRAINT [PK_AffCommission] PRIMARY KEY CLUSTERED 
(
	[RefID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Affiliate Net winlost' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AffCommission', @level2type=N'COLUMN',@level2name=N'AffWinlost'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Member Gross Winlost' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AffCommission', @level2type=N'COLUMN',@level2name=N'MemberWinlost'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Member Net Winlost' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AffCommission', @level2type=N'COLUMN',@level2name=N'MemberSum'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Member Net Winlost' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AffCommission', @level2type=N'COLUMN',@level2name=N'MemberDeposit'
GO
/****** Object:  Table [dbo].[AdminUser]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AdminUser](
	[custid] [int] IDENTITY(1,1) NOT NULL,
	[PageAccess] [nvarchar](500) NULL,
	[createdate] [datetime] NULL,
	[creator] [int] NULL,
	[GroupID] [int] NULL,
	[Closed] [bit] NULL,
	[logincount] [tinyint] NULL,
	[iplogin] [varchar](20) NULL,
	[lastlogged] [smalldatetime] NULL,
	[on_sessionid] [int] NULL,
	[Username] [varchar](30) NULL,
	[UserPwd] [varchar](40) NULL,
	[RoleId] [tinyint] NULL,
	[PwdExpiry] [datetime] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
 CONSTRAINT [PK_Affiliate_User] PRIMARY KEY CLUSTERED 
(
	[custid] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [AccInfoData]
) ON [AccInfoData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AdminNotes]    Script Date: 05/16/2013 07:47:54 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
/****** Object:  Table [dbo].[AdminFavorite]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminFavorite](
	[AdminID] [int] NOT NULL,
	[AffID] [int] NOT NULL,
 CONSTRAINT [PK_AdminFavorite] PRIMARY KEY CLUSTERED 
(
	[AdminID] ASC,
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]
GO
/****** Object:  Table [dbo].[AdminBranch]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminBranch](
	[AdminID] [int] NOT NULL,
	[BranchID] [smallint] NOT NULL,
 CONSTRAINT [PK_AdminBranch] PRIMARY KEY CLUSTERED 
(
	[AdminID] ASC,
	[BranchID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[LogType]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogType](
	[TypeID] [smallint] IDENTITY(1,1) NOT NULL,
	[TypeName] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,
 CONSTRAINT [PK_LogType] PRIMARY KEY CLUSTERED 
(
	[TypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[Language]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Language](
	[LanguageID] [varchar](8) NOT NULL,
	[LanguageName] [nvarchar](255) NOT NULL,
	[CountryID] [varchar](8) NOT NULL,
	[Creator] [int] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[Order] [smallint] NULL,
 CONSTRAINT [PK_Language] PRIMARY KEY CLUSTERED 
(
	[LanguageID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IP]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IP](
	[ipfrom] [bigint] NOT NULL,
	[ipto] [bigint] NOT NULL,
	[registry] [nvarchar](255) NULL,
	[assigned] [nvarchar](255) NULL,
	[countryshort] [nvarchar](3) NULL,
	[countryid] [nvarchar](8) NULL,
	[countrylong] [nvarchar](255) NULL,
	[from] [nvarchar](30) NULL,
	[to] [nvarchar](30) NULL,
	[region] [varchar](128) NULL,
	[city] [varchar](128) NULL
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GroupSettingHistory]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupSettingHistory](
	[GroupID] [int] NOT NULL,
	[ProductID] [tinyint] NOT NULL,
	[TierID] [tinyint] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[MinAmount] [money] NOT NULL,
	[MaxAmount] [money] NOT NULL,
	[MinQM] [int] NOT NULL,
	[MaxQM] [int] NOT NULL,
	[Commission] [decimal](9, 8) NOT NULL,
 CONSTRAINT [PK_GroupSettingHistory] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[ProductID] ASC,
	[TierID] ASC,
	[MonthDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[GroupSetting]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupSetting](
	[GroupID] [int] NOT NULL,
	[ProductID] [tinyint] NOT NULL,
	[TierID] [tinyint] NOT NULL,
	[MinAmount] [money] NOT NULL,
	[MaxAmount] [money] NOT NULL,
	[MinQM] [int] NOT NULL,
	[MaxQM] [int] NOT NULL,
	[Commission] [decimal](9, 8) NOT NULL,
 CONSTRAINT [PK_GroupSetting] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[ProductID] ASC,
	[TierID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[ExchangeDaily]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ExchangeDaily](
	[Date] [smalldatetime] NOT NULL,
	[ExchangeID] [smallint] NOT NULL,
	[USD] [float] NOT NULL,
	[USD_Market] [float] NOT NULL,
	[EUR] [float] NULL,
	[EUR_Market] [float] NULL,
	[CNY] [float] NULL,
	[CNY_Market] [float] NULL,
	[UUS] [float] NULL,
	[UUS_Market] [float] NULL,
	[MYR] [float] NULL,
	[MYR_Market] [float] NULL,
	[Code] [varchar](5) NULL,
	[DepositPercent] [float] NULL,
	[WithdrawalPercent] [float] NULL,
	[IsAutoRefresh] [bit] NULL,
 CONSTRAINT [PK_ExchangeDaily] PRIMARY KEY CLUSTERED 
(
	[Date] ASC,
	[ExchangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ExchangeData]
) ON [ExchangeData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Exchange]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Exchange](
	[ExchangeID] [smallint] NOT NULL,
	[Code] [varchar](5) NULL,
	[Currency] [nvarchar](50) NOT NULL,
	[Creator] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[IsAutoRefresh] [bit] NOT NULL,
	[Prefix] [nvarchar](255) NULL,
	[DepositPercent] [float] NULL,
	[WithdrawalPercent] [float] NULL,
	[USD] [float] NULL,
	[USD_Market] [float] NULL,
	[EUR] [float] NULL,
	[EUR_Market] [float] NULL,
	[CNY] [float] NULL,
	[CNY_Market] [float] NULL,
	[UUS] [float] NULL,
	[UUS_Market] [float] NULL,
	[MYR] [float] NULL,
	[MYR_Market] [float] NULL,
 CONSTRAINT [PK_Exchange] PRIMARY KEY NONCLUSTERED 
(
	[ExchangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ErrorLog]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ErrorLog](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[ExMessage] [nvarchar](255) NULL,
	[StackTrace] [nvarchar](max) NULL,
	[LogDate] [datetime] NULL,
	[SiteID] [int] NULL,
	[IP] [varchar](30) NULL,
	[Browser] [varchar](50) NULL,
	[OS] [varchar](50) NULL,
	[SessionID] [varchar](255) NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [UserLogData]
) ON [UserLogData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EmailHistory]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EmailHistory](
	[MID] [int] IDENTITY(1,1) NOT NULL,
	[Content] [nvarchar](4000) NOT NULL,
	[Sender] [nvarchar](100) NOT NULL,
	[Creator] [int] NULL,
	[AffId] [int] NULL,
	[AffName] [varchar](30) NULL,
	[Email] [nvarchar](50) NOT NULL,
	[Subject] [nvarchar](2000) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[IP] [varchar](23) NOT NULL,
	[Browser] [nvarchar](100) NOT NULL,
	[SessionID] [varchar](200) NOT NULL,
 CONSTRAINT [PK_EmailHistory] PRIMARY KEY CLUSTERED 
(
	[MID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [EmailData]
) ON [EmailData]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DeductionType]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionType](
	[DTypeID] [tinyint] NOT NULL,
	[TransTypeID] [tinyint] NULL,
	[ProductID] [tinyint] NULL,
	[DTypeName] [nvarchar](50) NULL,
	[DTypeDesc] [nvarchar](100) NULL,
	[DeductedPercentage] [float] NULL,
 CONSTRAINT [PK_DeductionType] PRIMARY KEY CLUSTERED 
(
	[DTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[DeductionSettingHistory]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSettingHistory](
	[GroupID] [int] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[DeductionID] [tinyint] NOT NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
 CONSTRAINT [PK_DeductionSettingHistory] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[MonthDate] ASC,
	[DeductionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[DeductionSetting]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSetting](
	[GroupID] [int] NOT NULL,
	[DeductionID] [tinyint] NOT NULL,
	[DeductedPercentage] [decimal](9, 8) NULL,
 CONSTRAINT [PK_DeductionSetting] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[DeductionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[CurrencyConverter]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CurrencyConverter](
	[ApplicationID] [smallint] NOT NULL,
	[PartnerCurrency] [varchar](50) NOT NULL,
	[ExchangeID] [smallint] NULL,
	[CreatedDate] [datetime] NULL,
	[PartnerExchangeID] [smallint] NULL,
 CONSTRAINT [PK_CurrencyConverter] PRIMARY KEY CLUSTERED 
(
	[ApplicationID] ASC,
	[PartnerCurrency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Currency]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Currency](
	[CurrencyID] [smallint] NOT NULL,
	[CurrencyCode] [varchar](5) NULL,
	[CurrencyName] [varchar](255) NULL,
	[FontCode2000] [nvarchar](50) NULL,
	[FontCodeMS] [nvarchar](50) NULL,
	[UnicodeDecimal] [varchar](50) NULL,
	[UnicodeHexa] [varchar](50) NULL,
	[GraphicImage] [binary](50) NULL,
 CONSTRAINT [PK_Currency] PRIMARY KEY CLUSTERED 
(
	[CurrencyID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Country]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Country](
	[CountryID] [nvarchar](6) NOT NULL,
	[CountryName] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](100) NULL,
	[Icon] [nvarchar](100) NULL,
	[DisplayOrder] [smallint] NULL,
	[IsEnabled] [bit] NULL,
 CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[CountryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]
GO
/****** Object:  Table [dbo].[CommGroupHistory]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroupHistory](
	[GroupID] [int] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[GroupName] [nvarchar](100) NULL,
	[CreatedDate] [datetime] NULL,
	[Creator] [int] NULL,
	[IsDeleted] [bit] NULL,
	[Description] [nvarchar](100) NULL,
	[QualifiedAmount] [money] NULL,
	[Currency] [smallint] NULL,
 CONSTRAINT [PK_CommGroupHistory] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[MonthDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[CommGroup]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroup](
	[GroupID] [int] NOT NULL,
	[GroupName] [nvarchar](100) NULL,
	[CreatedDate] [datetime] NULL,
	[Creator] [int] NULL,
	[IsDeleted] [bit] NULL,
	[Description] [nvarchar](100) NULL,
	[QualifiedAmount] [money] NULL,
	[Currency] [smallint] NULL,
 CONSTRAINT [PK_CommGroup_V2] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[UserLog]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog](
	[RefNo] [int] NOT NULL,
	[TypeID] [int] NOT NULL,
	[AffID] [int] NOT NULL,
	[Creator] [int] NULL,
	[LoggedDate] [datetime] NULL,
	[SPName] [varchar](50) NULL,
	[Details] [nvarchar](4000) NULL,
	[IP] [varchar](20) NULL
) ON [UserLogYearly_Scheme]([LoggedDate])
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MemberDailyTransaction]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberDailyTransaction](
	[UserName] [varchar](30) NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[AffID] [int] NOT NULL,
	[Currency] [smallint] NOT NULL,
	[AffCurrency] [smallint] NOT NULL,
	[AffExRate] [float] NULL,
	[SysCurrency] [smallint] NOT NULL,
	[SysExRate] [float] NOT NULL,
	[Deposit] [money] NOT NULL,
	[Withdrawal] [money] NOT NULL,
	[Bonus] [money] NOT NULL,
	[Adjustment] [money] NOT NULL,
	[PSP] [money] NOT NULL,
	[Marketing] [money] NOT NULL,
	[MemOddsFee] [money] NULL,
 CONSTRAINT [PK_MemberDailyTransaction] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC,
	[WinlostDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MemberDailyYearly_Scheme]([WinlostDate])
) ON [MemberDailyYearly_Scheme]([WinlostDate])
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MemberDaily]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberDaily](
	[UserName] [varchar](30) NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[ProductID] [tinyint] NOT NULL,
	[AffID] [int] NULL,
	[IBCCustID] [int] NULL,
	[Currency] [smallint] NOT NULL,
	[AffCurrency] [smallint] NULL,
	[AffExRate] [float] NULL,
	[SysCurrency] [smallint] NULL,
	[SysExRate] [float] NULL,
	[Deposit] [money] NOT NULL,
	[Withdrawal] [money] NOT NULL,
	[Bonus] [money] NOT NULL,
	[Adjustment] [money] NOT NULL,
	[Turnover] [money] NOT NULL,
	[Outstanding] [money] NOT NULL,
	[Winlost] [money] NOT NULL,
	[DrawGame] [money] NOT NULL,
	[PSP] [money] NOT NULL,
	[Marketing] [money] NOT NULL,
	[MemWinlostFake] [money] NULL,
	[MemOddsFee] [money] NULL,
	[MemPLayTechFee] [money] NULL,
 CONSTRAINT [PK_MemberDaily] PRIMARY KEY CLUSTERED 
(
	[UserName] ASC,
	[WinlostDate] ASC,
	[ProductID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [MemberDailyYearly_Scheme]([WinlostDate])
) ON [MemberDailyYearly_Scheme]([WinlostDate])
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ClickStatisticsSum]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClickStatisticsSum](
	[AffID] [int] NOT NULL,
	[DomainReferrer] [nvarchar](300) NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[SportCode] [varchar](50) NOT NULL,
	[LanguageCode] [varchar](10) NOT NULL,
	[TotalClick] [int] NULL,
	[UniqueClick] [int] NULL,
	[TotalSignup] [int] NULL,
	[TotalDeposit] [int] NULL,
 CONSTRAINT [PK_Affiliate_ClickStatisticsSum] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[DomainReferrer] ASC,
	[Date] ASC,
	[SportCode] ASC,
	[LanguageCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ClickSumYearly_Scheme]([Date])
) ON [ClickSumYearly_Scheme]([Date])
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ClickStatistics_bk]    Script Date: 05/16/2013 07:47:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClickStatistics_bk](
	[ClickID] [bigint] NOT NULL,
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
	[LanguageCode] [varchar](10) NULL,
	[SportCode] [varchar](50) NULL,
	[RedirectURL] [nvarchar](256) NULL,
	[Status] [tinyint] NULL,
	[ClickCount] [int] NULL
) ON [ClickStatisticsHalfYear_Scheme]([Date])
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Default [DF_Affiliate_Note_UpdateDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AdminNotes] ADD  CONSTRAINT [DF_Affiliate_Note_UpdateDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
/****** Object:  Default [DF_Affiliate_User_createdate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AdminUser] ADD  CONSTRAINT [DF_Affiliate_User_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
/****** Object:  Default [DF_AffCommission_Bonus]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffCommission] ADD  CONSTRAINT [DF_AffCommission_Bonus]  DEFAULT ((0)) FOR [HasBonus]
GO
/****** Object:  Default [DF_AffCommission_Adjustment]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffCommission] ADD  CONSTRAINT [DF_AffCommission_Adjustment]  DEFAULT ((0)) FOR [HasAdjustment]
GO
/****** Object:  Default [DF_AffCommission_IsMarketing]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffCommission] ADD  CONSTRAINT [DF_AffCommission_IsMarketing]  DEFAULT ((0)) FOR [HasMarketing]
GO
/****** Object:  Default [DF_AffCommission_hasPsP]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffCommission] ADD  CONSTRAINT [DF_AffCommission_hasPsP]  DEFAULT ((0)) FOR [HasPSP]
GO
/****** Object:  Default [DF_AffDomain_CreateDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_AffDomain_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_AffDomainControl_CreateDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffDomainControl] ADD  CONSTRAINT [DF_AffDomainControl_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_AffDomainControl_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffDomainControl] ADD  CONSTRAINT [DF_AffDomainControl_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF__Aff_Funct__Modif__3EA9ABCB]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF__Aff_Funct__Modif__3EA9ABCB]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF__Aff_Funct__Displ__3F9DD004]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF__Aff_Funct__Displ__3F9DD004]  DEFAULT ((7)) FOR [DisplayOrder]
GO
/****** Object:  Default [DF_Aff_GroupInfo_GroupName]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_GroupName]  DEFAULT ('') FOR [GroupName]
GO
/****** Object:  Default [DF_Aff_GroupInfo_GroupDesc]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_GroupDesc]  DEFAULT ('') FOR [GroupDesc]
GO
/****** Object:  Default [DF_Aff_GroupInfo_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Aff_GroupInfo_DisplayOrder]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_DisplayOrder]  DEFAULT ((5)) FOR [DisplayOrder]
GO
/****** Object:  Default [DF__Aff_Group__Syste__1BF4A114]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF__Aff_Group__Syste__1BF4A114]  DEFAULT ('AFFILIATE') FOR [System]
GO
/****** Object:  Default [DF_Aff_GroupPolicy_Policy]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_Policy]  DEFAULT ((0)) FOR [Policy]
GO
/****** Object:  Default [DF_Aff_GroupPolicy_CreateDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_Aff_GroupPolicy_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Affiliate_AffInfo_GroupID]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_Affiliate_AffInfo_GroupID]  DEFAULT ((0)) FOR [GroupID]
GO
/****** Object:  Default [DF_Affiliate_AffInfo_IsClosed]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_Affiliate_AffInfo_IsClosed]  DEFAULT ((0)) FOR [IsClosed]
GO
/****** Object:  Default [DF_AffInfo_AffType]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_AffType]  DEFAULT ((1)) FOR [AffType]
GO
/****** Object:  Default [DF_AffInfo_IsPageEnabled]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsPageEnabled]  DEFAULT ((0)) FOR [IsPageEnabled]
GO
/****** Object:  Default [DF_AffInfo_IsLocked]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsLocked]  DEFAULT ((0)) FOR [IsLocked]
GO
/****** Object:  Default [DF_Aff_MemberPolicy_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_Aff_MemberPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_Affiliate_Banners_LastUpdate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[Banners] ADD  CONSTRAINT [DF_Affiliate_Banners_LastUpdate]  DEFAULT (getdate()) FOR [LastUpdate]
GO
/****** Object:  Default [DF_Banners_Type]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[Banners] ADD  CONSTRAINT [DF_Banners_Type]  DEFAULT ((0)) FOR [Type]
GO
/****** Object:  Default [DF_Banners_Version]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[Banners] ADD  CONSTRAINT [DF_Banners_Version]  DEFAULT ((1)) FOR [Version]
GO
/****** Object:  Default [DF_ClickStatistics_Status]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_Status]  DEFAULT ((0)) FOR [Status]
GO
/****** Object:  Default [DF_ClickStatistics_ClickCount]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_ClickCount]  DEFAULT ((1)) FOR [ClickCount]
GO
/****** Object:  Default [DF_CurrencyConverter_ApplicationID]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[CurrencyConverter] ADD  CONSTRAINT [DF_CurrencyConverter_ApplicationID]  DEFAULT ((1)) FOR [ApplicationID]
GO
/****** Object:  Default [DF_Affiliate_EmailHistory_createdate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_Affiliate_EmailHistory_createdate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
/****** Object:  Default [DF_GroupSetting_Commission]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[GroupSetting] ADD  CONSTRAINT [DF_GroupSetting_Commission]  DEFAULT ((0)) FOR [Commission]
GO
/****** Object:  Default [DF_GroupSettingHistory_Commission]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[GroupSettingHistory] ADD  CONSTRAINT [DF_GroupSettingHistory_Commission]  DEFAULT ((0)) FOR [Commission]
GO
/****** Object:  Default [DF_rptDepWinlost_aExRate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_aExRate]  DEFAULT ((0)) FOR [AffExRate]
GO
/****** Object:  Default [DF_rptDepWinlost_Deposit]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_Deposit]  DEFAULT ((0)) FOR [Deposit]
GO
/****** Object:  Default [DF_rptDepWinlost_Withdrawal]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_Withdrawal]  DEFAULT ((0)) FOR [Withdrawal]
GO
/****** Object:  Default [DF_rptDepWinlost_Bonus]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_Bonus]  DEFAULT ((0)) FOR [Bonus]
GO
/****** Object:  Default [DF_rptDepWinlost_Adjustment]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_Adjustment]  DEFAULT ((0)) FOR [Adjustment]
GO
/****** Object:  Default [DF_rptDepWinlost_Turnover]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_Turnover]  DEFAULT ((0)) FOR [Turnover]
GO
/****** Object:  Default [DF_MemberDaily_Outstanding]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_MemberDaily_Outstanding]  DEFAULT ((0)) FOR [Outstanding]
GO
/****** Object:  Default [DF_MemberDaily_Winlost]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_MemberDaily_Winlost]  DEFAULT ((0)) FOR [Winlost]
GO
/****** Object:  Default [DF_rptDepWinlost_DrawGame]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_rptDepWinlost_DrawGame]  DEFAULT ((0)) FOR [DrawGame]
GO
/****** Object:  Default [DF_MemberDaily_PSP]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_MemberDaily_PSP]  DEFAULT ((0)) FOR [PSP]
GO
/****** Object:  Default [DF_MemberDaily_Marketing]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDaily] ADD  CONSTRAINT [DF_MemberDaily_Marketing]  DEFAULT ((0)) FOR [Marketing]
GO
/****** Object:  Default [DF_MemberDailyRemoved_aExRate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_aExRate]  DEFAULT ((0)) FOR [AffExRate]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Deposit]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Deposit]  DEFAULT ((0)) FOR [Deposit]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Withdrawal]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Withdrawal]  DEFAULT ((0)) FOR [Withdrawal]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Bonus]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Bonus]  DEFAULT ((0)) FOR [Bonus]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Adjustment]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Adjustment]  DEFAULT ((0)) FOR [Adjustment]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Turnover]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Turnover]  DEFAULT ((0)) FOR [Turnover]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Outstanding]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Outstanding]  DEFAULT ((0)) FOR [Outstanding]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Winlost]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Winlost]  DEFAULT ((0)) FOR [Winlost]
GO
/****** Object:  Default [DF_MemberDailyRemoved_DrawGame]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_DrawGame]  DEFAULT ((0)) FOR [DrawGame]
GO
/****** Object:  Default [DF_MemberDailyRemoved_PSP]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_PSP]  DEFAULT ((0)) FOR [PSP]
GO
/****** Object:  Default [DF_MemberDailyRemoved_Marketing]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyRemoved] ADD  CONSTRAINT [DF_MemberDailyRemoved_Marketing]  DEFAULT ((0)) FOR [Marketing]
GO
/****** Object:  Default [DF_MemberDailyTransaction_AffExRate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_AffExRate]  DEFAULT ((0)) FOR [AffExRate]
GO
/****** Object:  Default [DF_MemberDailyTransaction_Deposit]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_Deposit]  DEFAULT ((0)) FOR [Deposit]
GO
/****** Object:  Default [DF_MemberDailyTransaction_Withdrawal]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_Withdrawal]  DEFAULT ((0)) FOR [Withdrawal]
GO
/****** Object:  Default [DF_MemberDailyTransaction_Bonus]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_Bonus]  DEFAULT ((0)) FOR [Bonus]
GO
/****** Object:  Default [DF_MemberDailyTransaction_Adjustment]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_Adjustment]  DEFAULT ((0)) FOR [Adjustment]
GO
/****** Object:  Default [DF_MemberDailyTransaction_PSP]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_PSP]  DEFAULT ((0)) FOR [PSP]
GO
/****** Object:  Default [DF_MemberDailyTransaction_Marketing]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_Marketing]  DEFAULT ((0)) FOR [Marketing]
GO
/****** Object:  Default [DF_MemberDailyTransaction_MemOddsFee]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDailyTransaction] ADD  CONSTRAINT [DF_MemberDailyTransaction_MemOddsFee]  DEFAULT ((0)) FOR [MemOddsFee]
GO
/****** Object:  Default [DF_MemberDomain_CreateDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDomain] ADD  CONSTRAINT [DF_MemberDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
/****** Object:  Default [DF_MemberDomain_ModifyDate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberDomain] ADD  CONSTRAINT [DF_MemberDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
/****** Object:  Default [DF_MemberInfo_IsRemoved]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_IsRemoved]  DEFAULT ((0)) FOR [IsRemoved]
GO
/****** Object:  Default [DF_MemberInfo_Recommend]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_Recommend]  DEFAULT ((0)) FOR [Recommend]
GO
/****** Object:  Default [DF_news_posteddate]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_news_posteddate]  DEFAULT (getdate()) FOR [PostedDate]
GO
/****** Object:  Default [DF_news_important]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_news_important]  DEFAULT ((0)) FOR [Important]
GO
/****** Object:  Default [DF_SystemSettings_Editable]    Script Date: 05/16/2013 07:47:54 ******/
ALTER TABLE [dbo].[SystemSettings] ADD  CONSTRAINT [DF_SystemSettings_Editable]  DEFAULT ((0)) FOR [Type]
GO


/* To prevent any potential data loss issues, you should review this script in detail before running it outside the context of the database designer.*/
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.Exchange ADD
	SGD float(53) NULL,
	SGD_Market float(53) NULL,
	IDR float(53) NULL,
	IDR_Market float(53) NULL,
	AUD float(53) NULL,
	AUD_Market float(53) NULL,
	CHF float(53) NULL,
	CHF_Market float(53) NULL,
	GBP float(53) NULL,
	GBP_Market float(53) NULL,
	THB float(53) NULL,
	THB_Market float(53) NULL,
	VND float(53) NULL,
	VND_Market float(53) NULL
GO

ALTER TABLE dbo.ExchangeDaily ADD
	SGD float(53) NULL,
	SGD_Market float(53) NULL,
	IDR float(53) NULL,
	IDR_Market float(53) NULL,
	AUD float(53) NULL,
	AUD_Market float(53) NULL,
	CHF float(53) NULL,
	CHF_Market float(53) NULL,
	GBP float(53) NULL,
	GBP_Market float(53) NULL,
	THB float(53) NULL,
	THB_Market float(53) NULL,
	VND float(53) NULL,
	VND_Market float(53) NULL

	GO
ALTER TABLE dbo.MemberDaily ADD
	AffTransfer money NULL,
	Transfer3rd money NULL,
	BetCount int NULL,
	PlayerComm money NULL

GO
 
 ALTER TABLE dbo.MemberDailyRemoved ADD
	AffTransfer money NULL,
	Transfer3rd money NULL,
	BetCount int NULL,
	PlayerComm money NULL

GO

ALTER TABLE dbo.AffDaily ADD
	MemAffTransfer money NULL,
	MemTransfer3rd money NULL,
	MemBetCount int NULL,
	MemPlayerComm money NULL
GO
ALTER TABLE dbo.AffDailySummary ADD
	MemAffTransfer money NULL,
	MemTransfer3rd money NULL,
	MemBetCount int NULL,
	MemPlayerComm money NULL,
	MemAffTransfer_aff money NULL,
	MemTransfer3rd_aff money NULL,	
	MemPlayerComm_aff money NULL
GO

ALTER TABLE dbo.Currency ADD
	MultipliedBy int NULL

GO



  
COMMIT

