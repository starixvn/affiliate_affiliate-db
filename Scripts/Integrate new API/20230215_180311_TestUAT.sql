/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
/*
	Created: 20221118@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Create new table to check data

*/
USE [Affiliate_12BET]
GO

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

CREATE NONCLUSTERED INDEX [IX_TpType_SubItem_CallTime] ON [dbo].[APIProduct_TimeTrackerTest]
(
	[TpType] ASC,
	[SubItem] ASC,
	[CallTime] ASC
) ON [ReportData]
GO

ALTER TABLE [dbo].[APIProduct_TimeTrackerTest] ADD  DEFAULT ((-1)) FOR [TpType]
GO

ALTER TABLE [dbo].[APIProduct_TimeTrackerTest] ADD  DEFAULT ('') FOR [SubItem]
GO

CREATE TABLE [dbo].[APIProduct_ImportQueueTest](
	[QueueId] [int] IDENTITY(1,1) NOT NULL,
	[CheckInTime] [smalldatetime] NULL,
	[FinishedTime] [smalldatetime] NULL,
	[WinlostDate] [smalldatetime] NULL,
	[LogDesc] [varchar](2000) NULL,
	[TpType] [int] NULL,
	[SubItem] [varchar](200) NULL,
	[JsonData] [nvarchar](max) NULL,
 CONSTRAINT [PK_APIProduct_ImportQueueTest] PRIMARY KEY CLUSTERED 
(
	[QueueId] ASC
) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]
GO

CREATE NONCLUSTERED INDEX [IX_CheckInTime] ON [dbo].[APIProduct_ImportQueueTest]
(
	[CheckInTime] ASC
) ON [ReportData]
GO

CREATE NONCLUSTERED INDEX [IX_TpType_SubItem_WinlostDate] ON [dbo].[APIProduct_ImportQueueTest]
(
	[TpType] ASC,
	[SubItem] ASC,
	[WinlostDate] ASC
) ON [ReportData]
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

CREATE TABLE [dbo].[bettrans_APIProductsTest](
	[TpType] [int] NOT NULL,
	[SubItem] [varchar](200) NOT NULL,
	[Bet] [money] NULL,
	[BetStatus] [varchar](10) NULL,
	[GamePlatform] [varchar](20) NULL,
	[IsHedgebet] [bit] NULL,
	[ThirdPartyId] [int] NULL,
	[TransactionbDatetime] [datetime] NULL,
	[TransactionId] [varchar](20) NOT NULL,
	[Username] [varchar](50) NULL,
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

CREATE CLUSTERED INDEX [CIX_WinlostDate_TpType_SubItem_IBCCustId] ON [dbo].[bettrans_APIProductsTest]
(
	[WinlostDate] ASC,
	[TpType] ASC,
	[SubItem] ASC,
	[IBCCustId] ASC
) ON [ReportData]
GO

CREATE TABLE [dbo].[ProductsTest](
	[ProductId] [int] NOT NULL,
	[ProductName] [varchar](100) NOT NULL,
	[ProductPrefix] [varchar](10) NULL,
	[IsIBC] [bit] NULL,
	[TransferType] [tinyint] NULL,
	[Enabled] [bit] NULL,
	[IsTest] [bit] NULL,
	[EndOfSupportDate] [smalldatetime] NULL,
	[ReleasedDate] [smalldatetime] NULL,
 CONSTRAINT [PK_ProductsTest] PRIMARY KEY CLUSTERED 
(
	[ProductId] ASC
) ON [ReportData]
) ON [ReportData]
GO

ALTER TABLE [dbo].ProductsTest ADD  CONSTRAINT [DF_ProductsTest_IsMBC]  DEFAULT ((0)) FOR [IsIBC]
GO

ALTER TABLE [dbo].ProductsTest ADD  CONSTRAINT [DF_ProductsTest_TransferType]  DEFAULT ((0)) FOR [TransferType]
GO

ALTER TABLE [dbo].ProductsTest ADD  CONSTRAINT [DF_ProductsTest_Enabled]  DEFAULT ((0)) FOR [Enabled]
GO

ALTER TABLE [dbo].ProductsTest ADD  CONSTRAINT [DF_ProductsTest_IsTest]  DEFAULT ((0)) FOR [IsTest]
GO

CREATE TABLE [dbo].[SystemSettingsTest](
	[SID] [int] IDENTITY(1,1) NOT NULL,
	[SName] [varchar](50) NULL,
	[SValue] [varchar](200) NULL,
 CONSTRAINT [PK_SystemSettingsTest] PRIMARY KEY CLUSTERED 
(
	[SID] ASC
) ON [DATA]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX [IX_SName] ON [dbo].[SystemSettingsTest]
(
	[SName] ASC
)
INCLUDE([SValue]) ON [DATA]
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
) ON [ReportData]
GO

CREATE NONCLUSTERED INDEX [IX_AffId_ProductId] ON [dbo].[rptMemberDailyTest]
(
	[AffId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss],[AffExRate]) ON [ReportData]
GO

INSERT INTO SystemSettingsTest ([SName], [SValue])
VALUES ('AFF_CommissionDate', '2022-11-30')

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId)
VALUES (9, '', 10), (25, '', 41), (26, '', 42)

INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES 
(10	,'ExcludeTicketStatus', '')	
,(10	,'LastQueueId', '0')
,(10	,'LaunchDate',	'2018-10-01')
,(10	,'SourceTable',	'APIProduct_ImportQueueTest')
,(10	,'TimeZone',	'8')
,(41	,'ExcludeTicketStatus','')
,(41	,'LastQueueId',	'0')
,(41	,'LaunchDate',	'2022-12-01')
,(41	,'SourceTable', 'APIProduct_ImportQueueTest')
,(41	,'TimeZone',	'8')
,(42	,'ExcludeTicketStatus', '')
,(42	,'LastQueueId',	'0')
,(42	,'LaunchDate', '2022-12-01')
,(42	,'SourceTable',	'APIProduct_ImportQueueTest')
,(42	,'TimeZone',	'8')

INSERT INTO dbo.ProductsTest(ProductId,ProductName,ProductPrefix,IsIBC,TransferType,Enabled,IsTest,EndOfSupportDate,ReleasedDate)
SELECT ProductId,ProductName,ProductPrefix,IsIBC,TransferType,Enabled,IsTest,EndOfSupportDate,ReleasedDate
FROM dbo.Products WITH(NOLOCK)

INSERT INTO [ProductsTest] (ProductId,ProductName,ProductPrefix,IsIBC,TransferType,Enabled,IsTest,EndOfSupportDate,ReleasedDate)
VALUES 
(41, '12Garnet - AVP Mini', '12AVPM', 0, 0, 1, 0, null, '2022-12-01')
,(42, '12Garnet - AVP Slot', '12AVPS', 0, 0, 1, 0, null, '2022-12-01')

UPDATE [ProductsTest] WITH(ROWLOCK, UPDLOCK)
	SET ProductName = '12Opal - eBet'
WHERE PRODUCTID = 10

