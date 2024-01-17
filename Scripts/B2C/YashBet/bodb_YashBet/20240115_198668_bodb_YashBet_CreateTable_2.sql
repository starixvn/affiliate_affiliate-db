/*<info serverAlias="DBYASHBET-bodb_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task: Support new Aff Yashbet
		2. Create Table
*/
USE bodb_YashBet
GO

/****** Object:  Table [dbo].[API_PushDataTracker]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[API_PushDataTracker](
	[PushTrackerId] [bigint] IDENTITY(1,1) NOT NULL,
	[CheckInTime] [datetime] NULL,
	[FinishedTime] [datetime] NULL,
	[StatusId] [tinyint] NULL,
	[PushDataType] [smallint] NULL,
	[PushDataInfo] [nvarchar](max) NULL,
 CONSTRAINT [PK_API_PushDataTracker] PRIMARY KEY NONCLUSTERED 
(
	[PushTrackerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO
/****** Object:  Index [CIX_PushDataTracker_PushDataType]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_PushDataTracker_PushDataType] ON [dbo].[API_PushDataTracker]
(
	[PushDataType] ASC,
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Table [dbo].[API_Queue]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[API_Queue](
	[QueueId] [bigint] IDENTITY(1,1) NOT NULL,
	[CheckInTime] [datetime] NULL,
	[FinishedTime] [datetime] NULL,
	[IsFinished] [bit] NULL,
	[XmlData] [xml] NULL,
	[DataSource] [varchar](200) NULL,
	[LogDesc] [varchar](2000) NULL,
 CONSTRAINT [PK_API_Queue] PRIMARY KEY NONCLUSTERED 
(
	[QueueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_DataSource]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_DataSource] ON [dbo].[API_Queue]
(
	[DataSource] ASC,
	[IsFinished] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[API_TimeTracker]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[API_TimeTracker](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DataSource] [varchar](200) NULL,
	[CalledTime] [datetime] NULL,
	[KeyValue] [varchar](200) NULL,
 CONSTRAINT [PK_API_TimeTracker] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_DataSource]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_DataSource] ON [dbo].[API_TimeTracker]
(
	[DataSource] ASC,
	[CalledTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO


/****** Object:  Table [dbo].[BonusInfo]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BonusInfo](
	[BonusId] [int] NOT NULL,
	[TransId] [varchar](30) NULL,
	[PromotionType] [tinyint] NOT NULL,
	[BonusCode] [varchar](50) NOT NULL,
	[CustId] [int] NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[CurrencyId] [tinyint] NOT NULL,
	[SiteId] [int] NOT NULL,
	[LockedAmount] [decimal](18, 4) NULL,
	[BonusAmount] [decimal](18, 4) NULL,
	[ExpiryTime] [datetime] NOT NULL,
	[BonusInfo] [nvarchar](max) NULL,
	[Memo] [varchar](100) NULL,
	[CreateTime] [datetime] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[WinlostDate]  AS (CONVERT([date],[CreateTime],(0))),
 CONSTRAINT [PK_BonusInfo] PRIMARY KEY NONCLUSTERED 
(
	[BonusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [CIX_BonusInfo]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_BonusInfo] ON [dbo].[BonusInfo]
(
	[WinlostDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[CustBonusSummary]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustBonusSummary](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CustId] [int] NULL,
	[CurrencyId] [int] NULL,
	[SiteId] [int] NULL,
	[DataSource] [varchar](128) NULL,
	[BonusType] [smallint] NULL,
	[BonusStatus] [tinyint] NULL,
	[BonusCode] [varchar](50) NULL,
	[BonusTime] [datetime] NULL,
	[BonusAmount] [money] NULL,
 CONSTRAINT [PK_CustBonusSummary] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_CustBonusSummary]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_CustBonusSummary] ON [dbo].[CustBonusSummary]
(
	[BonusTime] ASC,
	[SiteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[Customer]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer](
	[CustId] [int] NOT NULL,
	[SiteId] [int] NOT NULL,
	[UserName] [varchar](30) NULL,
	[CurrencyId] [tinyint] NULL,
	[UserLang] [varchar](4) NULL,
	[ActStatus] [tinyint] NULL,
	[AgentId] [int] NULL,
	[AllAgentId] [nvarchar](max) NULL,
	[UserLevel] [tinyint] NULL,
	[RegTime] [datetime] NULL,
	[IsTest] [tinyint] NULL,
	[Status] [tinyint] NULL,
	[TpUserName] [varchar](50) NULL,
	[TpSystemUserName] [varchar](50) NULL,
	[FirstDepositDate] [datetime] NULL,
	[FirstDepositAmount] [money] NULL,
	[UpdatedTime] [datetime] NULL,
	[MemberType] [int] NOT NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData] TEXTIMAGE_ON [SettingData]
GO

/****** Object:  Table [dbo].[DepositInfo]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DepositInfo](
	[DepositId] [int] NOT NULL,
	[TransId] [varchar](30) NULL,
	[DepositType] [tinyint] NULL,
	[CustId] [int] NULL,
	[UserName] [varchar](30) NULL,
	[CurrencyId] [tinyint] NULL,
	[SiteId] [int] NULL,
	[DepositInfo] [nvarchar](max) NULL,
	[Amount] [decimal](18, 4) NULL,
	[ActualDeposit] [decimal](18, 4) NULL,
	[CreateTime] [datetime] NULL,
	[TPCreateTime] [datetime] NULL,
	[CallbackTime] [datetime] NULL,
	[FirstDeposit] [bit] NULL,
	[ThirdId] [varchar](100) NULL,
	[RefId] [varchar](100) NULL,
	[DepositTime] [datetime] NULL,
	[Memo] [varchar](100) NULL,
	[PostScript] [varchar](45) NULL,
	[Comment] [varchar](500) NULL,
	[Status] [tinyint] NULL,
	[WinlostDate]  AS (CONVERT([date],[CreateTime],0)),
	[Flag] [int] NULL,
	[Operator] [varchar](30) NULL,
	[UpdateTime] [datetime] NULL,
 CONSTRAINT [PK_DepositInfo] PRIMARY KEY NONCLUSTERED 
(
	[DepositId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [CIX_DepositInfo]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_DepositInfo] ON [dbo].[DepositInfo]
(
	[WinlostDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[JobLog]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobLog](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[DataSource] [varchar](128) NULL,
	[OldData] [varchar](max) NULL,
	[NewData] [varchar](max) NULL,
	[WinlostDate] [datetime] NULL,
	[CheckInTime] [datetime] NULL,
	[IsSendMail] [bit] NULL,
 CONSTRAINT [PK_JobLog] PRIMARY KEY NONCLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO

/****** Object:  Table [dbo].[YashBet_SumWinloss]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[YashBet_SumWinloss](
	[CustId] [int] NULL,
	[UserName] [varchar](50) NULL,
	[IsTest] [bit] NULL,
	[Currency] [int] NULL,
	[SiteId] [int] NULL,
	[GameType] [int] NULL,
	[TransTime] [datetime] NULL,
	[SettledTime] [datetime] NULL,
	[TurnOver] [money] NULL,
	[ValidBet] [money] NULL,
	[Winloss] [money] NULL,
	[BetCount] [int] NULL,
	[StatusId] [tinyint] NULL,
	[Revenue] [money] NULL,
	[ProgressiveBet] [money] NULL,
	[ProgressiveWin] [money] NULL,
	[BonusId] [int] NULL
) ON [PS_YashBet_SumWinloss_Monthly]([SettledTime])
GO
/****** Object:  Index [CIX_YashBet_SumWinloss]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_YashBet_SumWinloss] ON [dbo].[YashBet_SumWinloss]
(
	[SettledTime] ASC,
	[SiteId] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PS_YashBet_SumWinloss_Monthly]([SettledTime])
GO

/****** Object:  Table [dbo].[RebateMLog]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RebateMLog](
	[Id] [int] NOT NULL,
	[CustId] [int] NULL,
	[CurrencyId] [tinyint] NULL,
	[RebateType] [tinyint] NULL,
	[UserName] [varchar](30) NULL,
	[SiteId] [int] NULL,
	[RedeemAmount] [decimal](18, 4) NULL,
	[BonusCode] [varchar](50) NULL,
	[Memo] [varchar](200) NULL,
	[RelId] [bigint] NULL,
	[CreateTime] [datetime] NULL,
	[Winlostdate]  AS (CONVERT([date],[CreateTime],0)),
 CONSTRAINT [PK_RebateMLog] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [CIX_RebateMLog]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_RebateMLog] ON [dbo].[RebateMLog]
(
	[Winlostdate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[SystemSettings]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SName] [varchar](50) NOT NULL,
	[SValue] [varchar](200) NULL,
 CONSTRAINT [PK_SystemSettings] PRIMARY KEY NONCLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
SET ANSI_PADDING ON
GO

/****** Object:  Table [dbo].[TpBetRecord]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpBetRecord](
	[TpId] [int] NOT NULL,
	[TransId] [varchar](100) NOT NULL,
	[GameType] [int] NOT NULL,
	[CustId] [varchar](45) NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[CurrencyId] [int] NOT NULL,
	[SiteId] [int] NOT NULL,
	[TpUserName] [varchar](50) NOT NULL,
	[TransTime] [datetime] NOT NULL,
	[SettledTime] [datetime] NOT NULL,
	[Stake] [decimal](20, 6) NOT NULL,
	[WinlostAmount] [decimal](20, 6) NOT NULL,
	[SettlementType] [tinyint] NOT NULL,
	[TicketStatus] [tinyint] NOT NULL,
	[OriginalState] [varchar](10) NULL,
	[TicketKey] [bigint] NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[WinlostDate] [smalldatetime] NULL,
	[ValidBet] [decimal](20, 6) NULL,
	[BonusId] [int] NULL,
	[Revenue] [decimal](20, 6) NULL,
	[ProgressiveBet] [decimal](20, 6) NULL,
	[ProgressiveWin] [decimal](20, 6) NULL,
 CONSTRAINT [PK_TpBetRecord] PRIMARY KEY CLUSTERED 
(
	[TpId] ASC,
	[TransId] ASC,
	[GameType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO

/****** Object:  Table [dbo].[TpExchange]    Script Date: 1/8/2024 12:02:30 AM ******/
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
/****** Object:  Table [dbo].[TpGameType]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpGameType](
	[Type] [int] NOT NULL,
	[TypeName] [varchar](45) NULL,
 CONSTRAINT [PK_TpGameType] PRIMARY KEY CLUSTERED 
(
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
/****** Object:  Table [dbo].[TpReport9W]    Script Date: 1/8/2024 12:02:30 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpReport9W](
	[SQ] [bigint] NOT NULL,
	[userId] [varchar](20) NULL,
	[agentId] [varchar](50) NULL,
	[eventId] [varchar](20) NULL,
	[marketId] [varchar](20) NULL,
	[settledDate] [datetime] NULL,
	[resettledDate] [datetime] NULL,
	[profitLoss] [decimal](20, 4) NULL,
	[marketTotal] [decimal](20, 4) NULL,
	[commission] [decimal](20, 4) NULL,
	[agentCommission] [decimal](20, 4) NULL,
	[stakeTotal] [decimal](20, 4) NULL,
	[CreateTime] [datetime] NULL,
	[UpdateTime] [datetime] NULL,
	[CustId] [int] NULL,
	[CurrencyId] [int] NULL,
	[SiteId] [int] NULL,
 CONSTRAINT [PK_TpReport9W] PRIMARY KEY NONCLUSTERED 
(
	[SQ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
/****** Object:  Index [CIX_TpReport9W]    Script Date: 1/8/2024 12:02:30 AM ******/
CREATE CLUSTERED INDEX [CIX_TpReport9W] ON [dbo].[TpReport9W]
(
	[settledDate] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO

/****** Object:  Table [dbo].[TpWager9W]    Script Date: 1/8/2024 12:02:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpWager9W](
	[betId] [varchar](50) NOT NULL,
	[userId] [varchar](20) NULL,
	[agentId] [varchar](50) NULL,
	[eventId] [varchar](10) NULL,
	[marketId] [varchar](50) NULL,
	[matchSettledDate] [datetime] NULL,
	[settledDate] [datetime] NULL,
	[betStatus] [varchar](20) NULL,
	[matchStake] [decimal](20, 4) NULL,
	[profitLoss] [decimal](20, 4) NULL,
	[CreateTime] [datetime] NULL,
	[UpdateTime] [datetime] NULL,
 CONSTRAINT [PK_TpWager9W] PRIMARY KEY CLUSTERED 
(
	[betId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO

/****** Object:  Table [dbo].[WithdrawalInfo]    Script Date: 1/8/2024 12:02:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WithdrawalInfo](
	[WithdrawalId] [int] NOT NULL,
	[TransId] [varchar](30) NULL,
	[WithdrawalType] [tinyint] NULL,
	[CustId] [int] NULL,
	[UserName] [varchar](35) NULL,
	[CurrencyId] [tinyint] NULL,
	[SiteId] [int] NULL,
	[WithdrawalInfo] [nvarchar](max) NULL,
	[Amount] [decimal](18, 2) NULL,
	[RefId] [varchar](100) NULL,
	[ChargeFee] [decimal](18, 2) NULL,
	[CreateTime] [datetime] NULL,
	[Memo] [varchar](200) NULL,
	[Comment] [varchar](500) NULL,
	[Status] [tinyint] NULL,
	[Flag] [int] NULL,
	[Operator] [varchar](30) NULL,
	[UpdateTime] [datetime] NULL,
	[WinlostDate]  AS (CONVERT([date],[CreateTime],(0))),
 CONSTRAINT [PK_WithdrawalInfo] PRIMARY KEY NONCLUSTERED 
(
	[WithdrawalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [CIX_WithdrawalInfo]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE CLUSTERED INDEX [CIX_WithdrawalInfo] ON [dbo].[WithdrawalInfo]
(
	[WinlostDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Index [IX_SiteId]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [IX_SiteId] ON [dbo].[Customer]
(
	[SiteId] ASC,
	[RegTime] ASC
)
INCLUDE([UpdatedTime],[IsTest],[ActStatus],[Status],[FirstDepositDate],[FirstDepositAmount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO

/****** Object:  Index [IX_TransTime]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [IX_TransTime] ON [dbo].[YashBet_SumWinloss]
(
	[TransTime] ASC
)
INCLUDE([GameType],[Currency],[TurnOver],[ValidBet],[Winloss],[Revenue],[BetCount],[StatusId],[UserName],[IsTest]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PS_YashBet_SumWinloss_Monthly]([SettledTime])
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_CustId]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [IX_CustId] ON [dbo].[TpBetRecord]
(
	[CustId] ASC,
	[GameType] ASC,
	[TicketStatus] ASC,
	[SettledTime] ASC
)
INCLUDE([TransTime],[TransId],[CurrencyId],[Stake],[ValidBet],[WinlostAmount],[Revenue],[ProgressiveWin],[ProgressiveBet]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
/****** Object:  Index [IX_WinlostDate_TicketStatus]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [IX_WinlostDate_TicketStatus] ON [dbo].[TpBetRecord]
(
	[WinlostDate] ASC,
	[TicketStatus] ASC
)
INCLUDE([Stake],[ValidBet],[WinlostAmount],[Revenue],[CustId],[UserName],[CurrencyId],[SiteId],[TransTime],[SettledTime],[BonusId],[SettlementType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
SET ANSI_PADDING ON
GO

/****** Object:  Index [IX_TpReport9W]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [IX_TpReport9W] ON [dbo].[TpReport9W]
(
	[userId] ASC,
	[eventId] ASC,
	[marketId] ASC,
	[settledDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [CIX_TpWager9W]    Script Date: 1/8/2024 12:02:31 AM ******/
CREATE NONCLUSTERED INDEX [CIX_TpWager9W] ON [dbo].[TpWager9W]
(
	[userId] ASC,
	[eventId] ASC,
	[marketId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
ALTER TABLE [dbo].[API_PushDataTracker] ADD  CONSTRAINT [DF_API_PushDataTracker_CheckInTime]  DEFAULT (getdate()) FOR [CheckInTime]
GO
ALTER TABLE [dbo].[API_PushDataTracker] ADD  CONSTRAINT [DF_API_PushDataTracker_StatusId]  DEFAULT ((0)) FOR [StatusId]
GO
ALTER TABLE [dbo].[API_PushDataTracker] ADD  CONSTRAINT [DF_API_PushDataTracker_DataTrackerType]  DEFAULT ((1)) FOR [PushDataType]
GO
ALTER TABLE [dbo].[API_Queue] ADD  CONSTRAINT [DF_API_Queue_CheckInTime]  DEFAULT (getdate()) FOR [CheckInTime]
GO
ALTER TABLE [dbo].[API_Queue] ADD  CONSTRAINT [DF_API_Queue_IsFinished]  DEFAULT ((0)) FOR [IsFinished]
GO
ALTER TABLE [dbo].[CustBonusSummary] ADD  CONSTRAINT [DF_CustBonusSummary_BonusStatus]  DEFAULT ((0)) FOR [BonusStatus]
GO
ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_UpdatedTime]  DEFAULT (getdate()) FOR [UpdatedTime]
GO
ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_MemberType]  DEFAULT ((1)) FOR [MemberType]
GO
ALTER TABLE [dbo].[JobLog] ADD  CONSTRAINT [DF_JobLog_CheckInTime]  DEFAULT (getdate()) FOR [CheckInTime]
GO
ALTER TABLE [dbo].[JobLog] ADD  CONSTRAINT [DF_JobLog_IsSendMail]  DEFAULT ((0)) FOR [IsSendMail]
GO