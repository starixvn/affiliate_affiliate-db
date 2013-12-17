USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AdminFavorite]    Script Date: 10/28/2009 03:09:50 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AdminNotes]    Script Date: 10/28/2009 03:10:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminNotes](
	[NoteID] [int] IDENTITY(1,1) NOT NULL,
	[Note] [nvarchar](1000) NOT NULL,
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Affiliate_Note_UpdateDate]  DEFAULT (getdate()),
	[AffID] [int] NOT NULL,
	[UpdatedBy] [int] NOT NULL,
 CONSTRAINT [PK_AdminNotes] PRIMARY KEY CLUSTERED 
(
	[NoteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]


USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffCommission]    Script Date: 11/10/2009 19:45:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffCommission](
	[RefID] [bigint] IDENTITY(1000000001,1) NOT NULL,
	[RelNo] [int] NULL,
	[AffID] [int] NOT NULL,
	[GroupID] [int] NOT NULL,
	[SportID] [tinyint] NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[QualifiedMember] [int] NOT NULL,
	[Commission] [decimal](9, 8) NOT NULL,
	[HasBonus] [bit] NOT NULL CONSTRAINT [DF_AffCommission_Bonus]  DEFAULT ((0)),
	[HasAdjustment] [bit] NOT NULL CONSTRAINT [DF_AffCommission_Adjustment]  DEFAULT ((0)),
	[HasMarketing] [bit] NULL CONSTRAINT [DF_AffCommission_IsMarketing]  DEFAULT ((0)),
	[HasPSP] [bit] NULL CONSTRAINT [DF_AffCommission_hasPsP]  DEFAULT ((0)),
	[AffWinlost] [money] NULL,
	[Status] [nvarchar](50) NULL,
	[MemberWinlost] [money] NULL,
	[MemberBonus] [money] NULL,
	[MemberAdjustment] [money] NULL,
	[MemberPSP] [money] NULL,
	[MemberSum] [money] NULL,
	[MemberTurnover] [money] NULL,
	[MemberDeposit] [money] NULL,
	[Marketing] [money] NULL,
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffDetail]    Script Date: 10/28/2009 03:12:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffDetail](
	[AffID] [int] NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[SiteURL] [varchar](100) NOT NULL,
	[MoreSiteURLs] [varchar](1000) NULL,
	[PreferredLanguage] [varchar](11) NULL,
	[Gender] [bit] NULL,
	[Address] [nvarchar](80) NULL,
	[Postal] [nvarchar](50) NULL,
	[City] [nvarchar](50) NULL,
	[State] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
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
 CONSTRAINT [PK_AffDetail] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffGroupHistory]    Script Date: 10/28/2009 03:13:40 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffInfo]    Script Date: 10/28/2009 03:14:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AffInfo](
	[AffID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](30) NOT NULL,
	[UserName2] [nvarchar](30) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[GroupID] [int] NULL CONSTRAINT [DF_Affiliate_AffInfo_GroupID]  DEFAULT ((0)),
	[Status] [varchar](30) NULL,
	[ApprovedDate] [smalldatetime] NULL,
	[IsClosed] [bit] NULL CONSTRAINT [DF_Affiliate_AffInfo_IsClosed]  DEFAULT ((0)),
	[Currency] [tinyint] NULL,
	[RegisteredDate] [smalldatetime] NULL,
	[Email] [nvarchar](50) NULL,
	[Password] [varchar](40) NULL,
	[AffType] [tinyint] NULL CONSTRAINT [DF_AffInfo_AffType]  DEFAULT ((0)),
 CONSTRAINT [PK_AffInfo] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffPayout]    Script Date: 10/28/2009 03:14:27 ******/
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
	[Amount] [money] NULL,
	[AffPayout] [money] NULL,
	[AffCurrency] [int] NULL,
	[MemberExRate] [float] NULL,
	[AffExRate] [float] NULL,
	[MemberCurrency] [int] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[AdminDesc] [nvarchar](300) NULL,
	[AffDesc] [nvarchar](300) NULL,
 CONSTRAINT [PK_AffPayout] PRIMARY KEY CLUSTERED 
(
	[RefID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffTrans]    Script Date: 10/28/2009 03:15:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffTrans](
	[TransID] [bigint] IDENTITY(1,1) NOT NULL,
	[AffID] [int] NULL,
	[TransDate] [datetime] NULL,
	[CompletedDate] [datetime] NULL,
	[Amount] [money] NULL,
	[Status] [nvarchar](50) NULL,
	[Description] [nvarchar](300) NULL,
	[Creator] [int] NULL,
	[Currency] [int] NULL,
	[ActualRate] [float] NULL,
	[TransType] [int] NULL,
	[RefID] [bigint] NULL,
	[AffExRate] [float] NULL,
 CONSTRAINT [PK_AffTrans] PRIMARY KEY CLUSTERED 
(
	[TransID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionData]
) ON [TransactionData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[BankTrans]    Script Date: 10/28/2009 03:15:28 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[Banners]    Script Date: 10/28/2009 03:20:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Banners](
	[BannerID] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [varchar](50) NOT NULL,
	[Category] [varchar](50) NULL,
	[Language] [varchar](50) NULL,
	[ImageType] [varchar](50) NULL,
	[Size] [varchar](50) NULL,
	[LastUpdate] [datetime] NULL CONSTRAINT [DF_Affiliate_Banners_LastUpdate]  DEFAULT (getdate()),
	[Currency] [varchar](5) NULL,
	[CreatedDate] [datetime] NULL,
	[UpdatedBy] [int] NULL,
	[Creator] [int] NULL,
 CONSTRAINT [PK_Banners] PRIMARY KEY CLUSTERED 
(
	[BannerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[BannerTypes]    Script Date: 10/28/2009 03:21:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BannerTypes](
	[Type] [varchar](50) NULL,
	[Value] [varchar](50) NULL,
	[DisplayOrder] [tinyint] NULL
) ON [DATA]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[ClickStatistics]    Script Date: 10/28/2009 03:22:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClickStatistics](
	[TrackingID] [int] NOT NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[IP] [varchar](23) NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[Browser] [nvarchar](50) NOT NULL,
	[URLReferrer] [nvarchar](300) NOT NULL
) ON [StatIndex]

GO
SET ANSI_PADDING OFF
USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[ClickStatistics_bk]    Script Date: 10/28/2009 03:23:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ClickStatistics_bk](
	[TrackingID] [int] NOT NULL,
	[UpdatedTime] [datetime] NOT NULL,
	[IP] [varchar](23) NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[Browser] [nvarchar](50) NOT NULL,
	[URLReferrer] [nvarchar](300) NOT NULL
) ON [StatData]

GO
SET ANSI_PADDING OFF
USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[ClickStatisticsSum]    Script Date: 10/28/2009 03:23:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatisticsSum](
	[AffID] [int] NOT NULL,
	[TrackingID] [int] NOT NULL,
	[Date] [smalldatetime] NOT NULL,
	[IsForMonth] [bit] NOT NULL,
	[TotalClick] [int] NULL,
	[UniqueClick] [int] NULL,
 CONSTRAINT [PK_Affiliate_ClickStatisticsSum] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[TrackingID] ASC,
	[Date] ASC,
	[IsForMonth] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [StatData]
) ON [StatData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[CommGroup]    Script Date: 10/28/2009 03:23:45 ******/
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
 CONSTRAINT [PK_CommGroup_V2] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[CommGroupHistory]    Script Date: 10/28/2009 03:24:02 ******/
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
 CONSTRAINT [PK_CommGroupHistory] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[MonthDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[DeductionSetting]    Script Date: 10/28/2009 03:24:18 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[DeductionSettingHistory]    Script Date: 10/28/2009 03:24:32 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[DeductionType]    Script Date: 10/28/2009 03:25:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionType](
	[DTypeID] [tinyint] IDENTITY(1,1) NOT NULL,
	[TransTypeID] [tinyint] NULL,
	[SportID] [tinyint] NULL,
	[DTypeName] [nvarchar](50) NULL,
	[DTypeDesc] [nvarchar](100) NULL,
 CONSTRAINT [PK_DeductionType] PRIMARY KEY CLUSTERED 
(
	[DTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[EmailHistory]    Script Date: 10/28/2009 03:25:42 ******/
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
	[CreatedDate] [datetime] NULL CONSTRAINT [DF_Affiliate_EmailHistory_createdate]  DEFAULT (getdate()),
	[IP] [varchar](23) NOT NULL,
	[Browser] [nvarchar](100) NOT NULL,
	[SessionID] [varchar](200) NOT NULL,
 CONSTRAINT [PK_EmailHistory] PRIMARY KEY CLUSTERED 
(
	[MID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[Exchange]    Script Date: 10/28/2009 03:26:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exchange](
	[UpdatedTime] [smalldatetime] NOT NULL,
	[ExchangeID] [int] NOT NULL,
	[Currency] [nvarchar](50) NOT NULL,
	[ActualRate] [float] NOT NULL,
	[ActualRate2] [float] NOT NULL,
	[Creator] [nvarchar](50) NULL,
 CONSTRAINT [PK_Exchange] PRIMARY KEY CLUSTERED 
(
	[UpdatedTime] ASC,
	[ExchangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[Exchange_Current]    Script Date: 10/28/2009 03:26:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exchange_Current](
	[ExchangeID] [int] NOT NULL,
	[Currency] [nvarchar](50) NOT NULL,
	[ActualRate] [float] NOT NULL,
	[ActualRate2] [float] NOT NULL,
	[Creator] [nvarchar](50) NULL,
 CONSTRAINT [PK_Exchange_Current] PRIMARY KEY CLUSTERED 
(
	[ExchangeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[GroupSetting]    Script Date: 10/28/2009 03:27:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupSetting](
	[GroupID] [int] NOT NULL,
	[SportType] [tinyint] NOT NULL,
	[TierID] [tinyint] NOT NULL,
	[MinAmount] [money] NOT NULL,
	[MaxAmount] [money] NOT NULL,
	[MinQM] [int] NOT NULL,
	[MaxQM] [int] NOT NULL,
	[Commission] [decimal](9, 8) NOT NULL CONSTRAINT [DF_GroupSetting_Commission]  DEFAULT ((0)),
 CONSTRAINT [PK_GroupSetting] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[SportType] ASC,
	[TierID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[GroupSettingHistory]    Script Date: 10/28/2009 03:27:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupSettingHistory](
	[GroupID] [int] NOT NULL,
	[SportType] [tinyint] NOT NULL,
	[TierID] [tinyint] NOT NULL,
	[MonthDate] [smalldatetime] NOT NULL,
	[MinAmount] [money] NOT NULL,
	[MaxAmount] [money] NOT NULL,
	[MinQM] [int] NOT NULL,
	[MaxQM] [int] NOT NULL,
	[Commission] [decimal](9, 8) NOT NULL CONSTRAINT [DF_GroupSettingHistory_Commission]  DEFAULT ((0)),
 CONSTRAINT [PK_GroupSettingHistory] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[SportType] ASC,
	[TierID] ASC,
	[MonthDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [SettingData]
) ON [SettingData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[LogType]    Script Date: 10/28/2009 03:27:56 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[MemberDaily]    Script Date: 11/10/2009 19:44:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberDaily](
	[WinlostDate] [smalldatetime] NOT NULL,
	[IBCCustID] [int] NOT NULL,
	[SportType] [tinyint] NOT NULL,
	[Currency] [int] NOT NULL,
	[Deposit] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Deposit]  DEFAULT ((0)),
	[Withdrawal] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Withdrawal]  DEFAULT ((0)),
	[Bonus] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Bonus]  DEFAULT ((0)),
	[Adjustment] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Adjustment]  DEFAULT ((0)),
	[Turnover] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_Turnover]  DEFAULT ((0)),
	[Outstanding] [money] NOT NULL CONSTRAINT [DF_MemberDaily_Outstanding]  DEFAULT ((0)),
	[Winlost] [money] NOT NULL CONSTRAINT [DF_MemberDaily_Winlost]  DEFAULT ((0)),
	[AWinlost] [money] NULL,
	[ABonus] [money] NULL,
	[AffExRate] [float] NULL CONSTRAINT [DF_rptDepWinlost_aExRate]  DEFAULT ((0)),
	[MemberExRate] [float] NULL CONSTRAINT [DF_MemberDaily_MemberExRate]  DEFAULT ((0)),
	[DrawGame] [money] NOT NULL CONSTRAINT [DF_rptDepWinlost_DrawGame]  DEFAULT ((0)),
	[PSP] [money] NOT NULL CONSTRAINT [DF_MemberDaily_PSP]  DEFAULT ((0)),
	[Marketing] [money] NOT NULL CONSTRAINT [DF_MemberDaily_Marketing]  DEFAULT ((0)),
	[AffID] [int] NULL,
 CONSTRAINT [PK_MemberDaily] PRIMARY KEY CLUSTERED 
(
	[WinlostDate] ASC,
	[IBCCustID] ASC,
	[SportType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportIndex]
) ON [ReportIndex]


USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[MemberInfo]    Script Date: 10/28/2009 03:28:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MemberInfo](
	[IBCCustID] [int] NOT NULL,
	[AffID] [int] NULL,
	[UserName] [varchar](30) NULL,
	[IBCUserName] [varchar](30) NULL,
	[CreatedDate] [datetime] NULL,
	[IsRemoved] [bit] NOT NULL CONSTRAINT [DF_MemberInfo_IsRemoved]  DEFAULT ((0)),
	[DepositCustID] [int] NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Currency] [int] NOT NULL CONSTRAINT [DF_MemberInfo_Currency]  DEFAULT ((0)),
	[Email] [nvarchar](50) NULL,
	[Recommend] [int] NOT NULL CONSTRAINT [DF_MemberInfo_Recommend]  DEFAULT ((0)),
 CONSTRAINT [PK_MemberInfo] PRIMARY KEY CLUSTERED 
(
	[IBCCustID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[MemberRemoval]    Script Date: 10/28/2009 03:29:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberRemoval](
	[IBCCustID] [int] NOT NULL,
	[RemovedDate] [datetime] NULL,
	[RemovedBy] [int] NULL,
 CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED 
(
	[IBCCustID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoData]
) ON [AccInfoData]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[News]    Script Date: 10/28/2009 03:30:49 ******/
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
	[PostedDate] [datetime] NULL CONSTRAINT [DF_news_posteddate]  DEFAULT (getdate()),
	[Important] [bit] NOT NULL CONSTRAINT [DF_news_important]  DEFAULT ((0)),
	[UpdatedBy] [int] NULL,
	[UpdatedDate] [datetime] NULL,
 CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED 
(
	[MsgID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[Ref]    Script Date: 10/28/2009 03:31:36 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[SportType]    Script Date: 10/28/2009 03:33:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SportType](
	[SportID] [tinyint] IDENTITY(1,1) NOT NULL,
	[SportName] [nvarchar](100) NULL,
	[QMTurnOver] [money] NULL,
 CONSTRAINT [PK_SportType] PRIMARY KEY CLUSTERED 
(
	[SportID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[SystemSettings]    Script Date: 10/28/2009 03:33:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[SID] [int] IDENTITY(1,1) NOT NULL,
	[SName] [varchar](50) NULL,
	[SValue] [varchar](200) NULL,
 CONSTRAINT [PK_SystemSettings] PRIMARY KEY CLUSTERED 
(
	[SID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[TrackingCode]    Script Date: 10/28/2009 03:34:12 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [StatData]
) ON [StatData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[TransType]    Script Date: 10/28/2009 03:34:34 ******/
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

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[UserLog]    Script Date: 10/28/2009 03:34:58 ******/
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
	[LoggedDate] [smalldatetime] NULL,
	[SPName] [varchar](50) NULL,
	[Details] [nvarchar](4000) NULL,
	[IP] [varchar](20) NULL
) ON [UserLogData]

GO
SET ANSI_PADDING OFF


USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[MemberDailyRemoved]    Script Date: 12/31/2009 20:53:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberDailyRemoved](
	[WinlostDate] [smalldatetime] NOT NULL,
	[IBCCustID] [int] NOT NULL,
	[SportType] [tinyint] NOT NULL,
	[Currency] [int] NOT NULL,
	[Deposit] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Deposit]  DEFAULT ((0)),
	[Withdrawal] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Withdrawal]  DEFAULT ((0)),
	[Bonus] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Bonus]  DEFAULT ((0)),
	[Adjustment] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Adjustment]  DEFAULT ((0)),
	[Turnover] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Turnover]  DEFAULT ((0)),
	[Outstanding] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Outstanding]  DEFAULT ((0)),
	[Winlost] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Winlost]  DEFAULT ((0)),
	[AWinlost] [money] NULL,
	[ABonus] [money] NULL,
	[AffExRate] [float] NULL CONSTRAINT [DF_MemberDailyRemoved_aExRate]  DEFAULT ((0)),
	[MemberExRate] [float] NULL CONSTRAINT [DF_MemberDailyRemoved_MemberExRate]  DEFAULT ((0)),
	[DrawGame] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_DrawGame]  DEFAULT ((0)),
	[PSP] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_PSP]  DEFAULT ((0)),
	[Marketing] [money] NOT NULL CONSTRAINT [DF_MemberDailyRemoved_Marketing]  DEFAULT ((0)),
	[AffID] [int] NULL,
 CONSTRAINT [PK_MemberDailyRemoved] PRIMARY KEY CLUSTERED 
(
	[WinlostDate] ASC,
	[IBCCustID] ASC,
	[SportType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportIndex]
) ON [ReportIndex]

/*These tables below are used for olf log data */
USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[UserLog_Login]    Script Date: 01/06/2010 03:10:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_Login](
	[LogID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[RoleID] [tinyint] NOT NULL,
	[SubAccID] [int] NOT NULL,
	[ServerID] [int] NOT NULL,
	[IP] [varchar](15) NOT NULL,
	[LogDate] [smalldatetime] NOT NULL
) ON  [UserLogData]

GO
SET ANSI_PADDING OFF

USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[UserLog_RunSP]    Script Date: 01/06/2010 03:10:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UserLog_RunSP](
	[logid] [int] IDENTITY(1,1) NOT NULL,
	[userid] [int],
	[spname] [varchar](50),
	[doing] [varchar](4000),
	[logdate] [datetime],
	[custid] [int]	
) ON  [UserLogData]

GO
SET ANSI_PADDING OFF