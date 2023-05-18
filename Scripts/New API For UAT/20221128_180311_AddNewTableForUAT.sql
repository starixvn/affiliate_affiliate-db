/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

CREATE TABLE [dbo].[APIProduct_TimeTrackerTest](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Currency] [int] NULL,
	[CallTime] [datetime] NULL,
	[TpType] [int] NULL,
	[SubItem] [varchar](200) NULL,
	CONSTRAINT [PK_APIProduct_TimeTrackerTest] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	) ON [ReportData]
) ON [ReportData]
GO

CREATE NONCLUSTERED INDEX [IX_TpType_SubItem] ON [dbo].[APIProduct_TimeTrackerTest]
(
	TpType ASC
	,SubItem ASC
)
INCLUDE([Currency],[CallTime])  ON [ReportData]
GO

CREATE TABLE [dbo].[APIProduct_ImportQueueTest](
	[QueueId] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NULL,
	[XmlData] [xml] NULL,
	[CheckInTime] [smalldatetime] NULL,
	[FinishedTime] [smalldatetime] NULL,
	[WinlostDate] [smalldatetime] NULL,
	[LogDesc] [varchar](2000) NULL,
	[JobType] [tinyint] NULL,
	[TpType] [int] NULL,
	[SubItem] [varchar](200) NULL,
	CONSTRAINT [PK_APIProduct_ImportQueueTest] PRIMARY KEY CLUSTERED 
	(
		[QueueId] ASC
	) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO

CREATE TABLE [dbo].[APIProductSettingsTest](
	[ProductId] [int] NOT NULL,
	[SettingName] [varchar](200) NOT NULL,
	[SettingValue] [varchar](200) NULL,
 CONSTRAINT [PK_APIProductSettingsTest] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC,
	[SettingName] ASC
) ON [SettingData]
) ON [SettingData]
GO

CREATE TABLE [dbo].[APIProductMappingSettingsTest](
	[TpType] [int] NOT NULL,
	[SubItem] [varchar](200) NOT NULL,
	[ProductId] [int] NULL,
 CONSTRAINT [PK_APIProductMappingSettingsTest] PRIMARY KEY CLUSTERED 
	(
		[TpType] ASC,
		[SubItem] ASC
	) ON [SettingData]
) ON [SettingData]
GO

CREATE NONCLUSTERED INDEX [IX_ProductId] ON [dbo].[APIProductMappingSettingsTest]
(
	[ProductId] ASC
) ON [SettingData]
GO

CREATE TABLE [dbo].[rptMemberDailyTest](
	[WinlostDate] [smalldatetime] NOT NULL,
	[AffId] [int] NULL,
	[IBCCustId] [int] NOT NULL,
	[ProductId] [int] NOT NULL,
	[Deposit] [money] NULL,
	[Withdrawal] [money] NULL,
	[Bonus] [money] NULL,
	[Adjustment] [money] NULL,
	[Turnover] [money] NULL,
	[Winloss] [money] NULL,
	[Currency] [int] NULL,
	[ExRate] [float] NULL,
	[AffExRate] [float] NULL,
	[AWinloss] [money] NULL,
	[AComm] [money] NULL,
	CONSTRAINT [PK_rptMemberDailyTest] PRIMARY KEY NONCLUSTERED 
	(
		[WinlostDate] ASC,
		[IBCCustId] ASC,
		[ProductId] ASC
	) ON [ReportData]
) ON [ReportData]
GO

ALTER TABLE [dbo].[rptMemberDailyTest] ADD  CONSTRAINT [DF_rptMemberDailyTest_AWinloss]  DEFAULT ((0)) FOR [AWinloss]
GO

ALTER TABLE [dbo].[rptMemberDailyTest] ADD  CONSTRAINT [DF_rptMemberDailyTest_AComm]  DEFAULT ((0)) FOR [AComm]
GO

CREATE CLUSTERED INDEX [CIX_WinlostDate_AffId_ProductId] ON [dbo].[rptMemberDailyTest]
(
	[WinlostDate] ASC,
	[AffId] ASC,
	[ProductId] ASC
)ON [ReportData]
GO

CREATE NONCLUSTERED INDEX [IX_AffId_ProductId] ON [dbo].[rptMemberDailyTest]
(
	[AffId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss],[AffExRate]) ON [ReportData]
GO

CREATE TABLE [dbo].[bettrans_APIProductsTest](
	[TpType] [int] NOT NULL,
	[SubItem] [varchar](200) NOT NULL,
	[Bet] [money] NULL,
	[BetStatus] [int] NULL,
	[DataInfo] [varchar](200) NULL,
	[GamePlatform] [varchar](200) NULL,
	[IsHedgebet] [bit] NULL,
	[ThirdPartyId] [int] NULL,
	[TransactionbDatetime] [datetime] NULL,
	[TransactionId] [bigint] NOT NULL,
	[Username] [varchar](500) NULL,
	[ValidBet] [money] NULL,
	[Win] [money] NULL,
	[IBCCustId] [int] NULL,
	[WinlostDate] [smalldatetime] NULL,
	CONSTRAINT [PK_bettrans_APIProductsTest] PRIMARY KEY NONCLUSTERED 
	(
		[TpType] ASC,
		[SubItem] ASC,
		[TransactionId] ASC
	) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX [CIX_WinlostDate_IBCCustId] ON [dbo].[bettrans_APIProductsTest]
(
	[WinlostDate] ASC,
	[IBCCustId] ASC
) ON [ReportData]
GO



