/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20241108@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		2. Create Table DB Affiliate_12B
*/
/****** Object:  Table [dbo].[ExchangeOanda] ******/
USE Affiliate_12B
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ExchangeOanda](
	[ExchangeDate] [SMALLDATETIME] NOT NULL,
	[ExchangeId] [INT] NOT NULL,
	[Code] [VARCHAR](5) NULL,
	[ActualRate] [FLOAT] NULL,
	[MYR] [FLOAT] NULL,
	[USD] [FLOAT] NULL,
	[THB] [FLOAT] NULL,
	[EUR] [FLOAT] NULL,
	[CNY] [FLOAT] NULL,
	[IDR] [FLOAT] NULL,
	[VND] [FLOAT] NULL,
	[INR] [FLOAT] NULL,
	[BDT] [FLOAT] NULL,
	CONSTRAINT [PK_ExchangeOanda] PRIMARY KEY CLUSTERED 
	(
		[ExchangeDate] ASC,
		[ExchangeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[TpExchange] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TpExchange](
	[TpExchangeId] [INT] NOT NULL,
	[ExchangeId] [INT] NULL,
	CONSTRAINT [PK_TpExchange] PRIMARY KEY NONCLUSTERED 
	(
		[TpExchangeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO


/****** Object:  Table [dbo].[SystemSettings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SystemSettings](
	[SID] [INT] IDENTITY(1,1) NOT NULL,
	[SName] [VARCHAR](50) NULL,
	[SValue] [VARCHAR](200) NULL,
	CONSTRAINT [PK_SystemSettings] PRIMARY KEY CLUSTERED 
	(
		[SID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_SName] ON [dbo].[SystemSettings]
(
	[SName] ASC
)
INCLUDE([SValue]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO


/****** Object:  Table [dbo].[AffTrans] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffTrans](
	[TransId] [BIGINT] IDENTITY(1,1) NOT NULL,
	[AffId] [INT] NULL,
	[TransDate] [DATETIME] NULL,
	[CompletedDate] [DATETIME] NULL,
	[Amount] [MONEY] NULL,
	[Status] [VARCHAR](50) NULL,
	[Description] [NVARCHAR](300) NULL,
	[Creator] [INT] NULL,
	[TransType] [INT] NULL,
	[RefId] [BIGINT] NULL,
	[AffCurrency] [INT] NULL,
	[AffRate] [FLOAT] NULL,
	CONSTRAINT [PK_AffTrans] PRIMARY KEY NONCLUSTERED 
	(
		[TransId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
) ON [TransactionData]
GO
--
SET ANSI_PADDING ON
GO
CREATE CLUSTERED INDEX [CIX_AffId] ON [dbo].[AffTrans]
(
	[AffId] ASC,
	[TransDate] ASC,
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_TransDate] ON [dbo].[AffTrans]
(
	[TransDate] ASC
)
INCLUDE([Amount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_RefID] ON [dbo].[AffTrans]
(
	[RefID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO


/****** Object:  Table [dbo].[AdminFavorite] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminFavorite](
	[AdminId] [INT] NOT NULL,
	[AffId] [INT] NOT NULL,
	CONSTRAINT [PK_AdminFavorite] PRIMARY KEY CLUSTERED 
	(
		[AdminId] ASC,
		[AffId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO


/****** Object:  Table [dbo].[AdminNotes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AdminNotes](
	[NoteID] [INT] IDENTITY(1,1) NOT NULL,
	[Note] [NVARCHAR](1000) NOT NULL,
	[UpdatedDate] [DATETIME] NOT NULL,
	[AffID] [INT] NOT NULL,
	[UpdatedBy] [INT] NOT NULL,
	CONSTRAINT [PK_AdminNotes] PRIMARY KEY CLUSTERED 
	(
		[NoteID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [INDEX]
) ON [AffData]
GO
--
ALTER TABLE [dbo].[AdminNotes] ADD  CONSTRAINT [DF_Affiliate_Note_UpdateDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO
--
CREATE NONCLUSTERED INDEX [IX_AffID] ON [dbo].[AdminNotes]
(
	[AffID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [INDEX]
GO


/****** Object:  Table [dbo].[AffDetail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDetail](
	[AffId] [INT] NOT NULL,
	[UserName] [VARCHAR](30) NOT NULL,
	[SiteURL] [VARCHAR](100) NOT NULL,
	[MoreSiteURLs] [VARCHAR](1000) NULL,
	[PreferredLanguage] [VARCHAR](11) NULL,
	[Gender] [BIT] NULL,
	[Address] [NVARCHAR](250) NULL,
	[Postal] [NVARCHAR](50) NULL,
	[City] [NVARCHAR](250) NULL,
	[State] [NVARCHAR](50) NULL,
	[Country] [NVARCHAR](50) NULL,
	[Phone] [VARCHAR](50) NULL,
	[MobilePhone] [VARCHAR](50) NULL,
	[Fax] [VARCHAR](50) NULL,
	[Question] [NVARCHAR](300) NULL,
	[Answer] [NVARCHAR](300) NULL,
	[PreferredPayment] [VARCHAR](20) NULL,
	[Player_Username] [VARCHAR](30) NULL,
	[Player_Currency] [INT] NULL,
	[Neteller_AccountID] [VARCHAR](50) NULL,
	[Moneybookers_Email] [NVARCHAR](50) NULL,
	[Wire_BankName] [NVARCHAR](100) NULL,
	[Wire_BankAddress] [NVARCHAR](200) NULL,
	[Wire_SwiftCode] [NVARCHAR](50) NULL,
	[Wire_AccountName] [NVARCHAR](100) NULL,
	[Wire_AccountNo] [VARCHAR](100) NULL,
	[Cheque_FullName] [NVARCHAR](200) NULL,
	[Cheque_Address] [NVARCHAR](200) NULL,
	[Cheque_City] [NVARCHAR](50) NULL,
	[Cheque_State] [NVARCHAR](50) NULL,
	[Cheque_Postal] [NVARCHAR](50) NULL,
	[Cheque_Country] [NVARCHAR](50) NULL,
	[BonusCode] [VARCHAR](20) NULL,
	[LastLoginDate] [DATETIME] NULL,
	[LastLoginIP] [NVARCHAR](20) NULL,
	[LoginCount] [TINYINT] NULL,
	[ValidCode] [NVARCHAR](30) NULL,
	[CodeExpiry] [DATETIME] NULL,
	[MailOption] [BIT] NULL,
	[NoSiteDesc] [NVARCHAR](1000) NULL,
	[ContactApps] [NVARCHAR](2000) NULL,
	[QuestionID] [TINYINT] NULL,
	[Player_CurrencyName] [NVARCHAR](50) NULL,
	[Player_CurrencyCode] [VARCHAR](3) NULL,
	[Player_CustId] [INT] NULL,
	[TransferLimit] [MONEY] NULL,
	[DisabledTransfer] [BIT] NULL,
	CONSTRAINT [PK_AffDetail] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
) ON [AccInfoData]
GO
--
ALTER TABLE [dbo].[AffDetail] ADD  CONSTRAINT [DF_AffDetail_DisabledTransfer]  DEFAULT ((1)) FOR [DisabledTransfer]
GO
--
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_PreferedLanguage] ON [dbo].[AffDetail]
(
	[PreferredLanguage] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO


/****** Object:  Table [dbo].[AffDomain] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDomain](
	[DomainId] [INT] IDENTITY(1,1) NOT NULL,
	[DomainName] [NVARCHAR](50) NOT NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[IsDeleted] [BIT] NULL,
	[IsSSL] [BIT] NULL,
	CONSTRAINT [PK_AffDomain] PRIMARY KEY CLUSTERED 
	(
		[DomainId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffDomain] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[AffDomain] ADD  CONSTRAINT [DF_AffDomain_IsSSL]  DEFAULT ((0)) FOR [IsSSL]
GO


/****** Object:  Table [dbo].[AffFunctionInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffFunctionInfo](
	[FuncId] [INT] IDENTITY(100000,1) NOT NULL,
	[FuncName] [NVARCHAR](50) NULL,
	[FuncNote] [NVARCHAR](2000) NULL,
	[FuncDesc] [NVARCHAR](50) NULL,
	[FuncRender] [TINYINT] NULL,
	[CreateDate] [DATETIME] NOT NULL,
	[ModifyDate] [DATETIME] NOT NULL,
	[DisplayOrder] [TINYINT] NULL,
	[Creator] [INT] NULL,
	[ParentId] [INT] NULL,
	[FileNames] [VARCHAR](2000) NULL,
	CONSTRAINT [PK_AffFunctionInfo] PRIMARY KEY CLUSTERED 
	(
		[FuncId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
--
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF_AffFunctionInfo_DisplayOrder]  DEFAULT ((7)) FOR [DisplayOrder]
GO


/****** Object:  Table [dbo].[AffGroupHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupHistory](
	[AffId] [INT] NOT NULL,
	[MonthDate] [DATETIME] NOT NULL,
	[GroupId] [INT] NOT NULL,
	[ParentAffId] [INT] NULL,
	[AllParentAffId] [VARCHAR](MAX) NULL,
	CONSTRAINT [PK_AffGroupHistory] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC,
		[MonthDate] ASC,
		[GroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData] TEXTIMAGE_ON [SettingData]
GO


/****** Object:  Table [dbo].[AffGroupInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupInfo](
	[GroupId] [INT] IDENTITY(1000,1) NOT NULL,
	[GroupName] [NVARCHAR](50) NOT NULL,
	[GroupDesc] [NVARCHAR](50) NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[DisplayOrder] [TINYINT] NULL,
	[Creator] [INT] NULL,
	CONSTRAINT [PK_AffGroupInfo] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_AffGroupInfo_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_AffGroupInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO


/****** Object:  Table [dbo].[AffGroupPolicy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffGroupPolicy](
	[GroupId] [INT] NOT NULL,
	[FuncId] [INT] NOT NULL,
	[Policy] [TINYINT] NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	CONSTRAINT [PK_AffGroupPolicy] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[FuncId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_AffGroupPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_AffGroupPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO


/****** Object:  Table [dbo].[Affiliate_User] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Affiliate_User](
	[CustId] [INT] IDENTITY(1000000000,1) NOT NULL,
	[PageAccess] [NVARCHAR](500) NULL,
	[CreateDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[GroupId] [INT] NULL,
	[Closed] [BIT] NULL,
	[LoginCount] [TINYINT] NULL,
	[IPLogin] [VARCHAR](20) NULL,
	[LastLogged] [SMALLDATETIME] NULL,
	[On_SessionId] [INT] NULL,
	[UserName] [VARCHAR](30) NULL,
	[UserPwd] [VARCHAR](40) NULL,
	[RoleId] [TINYINT] NULL,
	[PwdExpiry] [DATETIME] NULL,
	[FirstName] [NVARCHAR](50) NULL,
	[LastName] [NVARCHAR](50) NULL,
	CONSTRAINT [PK_Affiliate_User] PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[AffiliateCode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffiliateCode](
	[AffCode] [VARCHAR](20) NOT NULL,
	[AffId] [INT] NULL,
	CONSTRAINT [PK_AffiliateCode] PRIMARY KEY CLUSTERED 
	(
		[AffCode] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO


/****** Object:  Table [dbo].[AffInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffInfo](
	[AffId] [INT] IDENTITY(1,1) NOT NULL,
	[UserName] [NVARCHAR](30) NULL,
	[UserName2] [NVARCHAR](30) NULL,
	[FirstName] [NVARCHAR](50) NULL,
	[LastName] [NVARCHAR](50) NULL,
	[GroupId] [INT] NULL,
	[Status] [VARCHAR](30) NULL,
	[ApprovedDate] [DATETIME] NULL,
	[IsClosed] [BIT] NULL,
	[Currency] [INT] NULL,
	[RegisteredDate] [DATETIME] NULL,
	[Email] [NVARCHAR](50) NULL,
	[Password] [VARCHAR](40) NULL,
	[AffType] [TINYINT] NULL,
	[IsPageEnabled] [BIT] NULL,
	[Level] [TINYINT] NULL,
	[IsLocked] [BIT] NULL,
	[CasinoJoinedDate] [DATETIME] NULL,
	[ForceChangePass] [BIT] NULL,
	[SecretKey] [VARCHAR](50) NULL,
	[CurrencyName] [NVARCHAR](50) NULL,
	[CurrencyCode] [VARCHAR](3) NULL,
	[ParentAffId] [INT] NULL,
	[AllParentAffId] [VARCHAR](MAX) NULL,
	[IsSuspended] [BIT] NULL,
	[SuspendedDate] [DATETIME] NULL,
	[ApprovedBy] [INT] NULL,
	[DefaultCurrency] [INT] NULL,
	[AffCode] [VARCHAR](20) NULL,
	[IsRejected] [BIT] NULL,
	CONSTRAINT [PK_AffInfo] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
) ON [AccInfoData] TEXTIMAGE_ON [AccInfoData]
GO
--
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsClosed]  DEFAULT ((0)) FOR [IsClosed]
GO
ALTER TABLE [dbo].[AffInfo] ADD  CONSTRAINT [DF_AffInfo_IsRejected]  DEFAULT ((0)) FOR [IsRejected]
GO
--
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_GroupID] ON [dbo].[AffInfo]
(
	[GroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_UserName2] ON [dbo].[AffInfo]
(
	[UserName2] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_Email] ON [dbo].[AffInfo]
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_SearchAff] ON [dbo].[AffInfo]
(
	[Status] ASC,
	[IsClosed] ASC,
	[IsRejected] ASC,
	[RegisteredDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_Search] ON [dbo].[AffInfo]
(
	[UserName] ASC,
	[Status] ASC,
	[ApprovedDate] ASC,
	[AffType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_UserName] ON [dbo].[AffInfo]
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO


/****** Object:  Table [dbo].[AffLoginInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffLoginInfo](
	[AffId] [INT] NOT NULL,
	[LoginSessionId] [VARCHAR](30) NOT NULL,
	[LastLoginDate] [DATETIME] NULL,
	[LastLoginIP] [VARCHAR](50) NULL,
	[FailedLoginCount] [TINYINT] NULL,
	CONSTRAINT [PK_AffLoginInfo] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC,
		[LoginSessionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[AffMediaChannel] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMediaChannel](
	[AffId] [INT] NOT NULL,
	[ChannelCode] [VARCHAR](50) NOT NULL,
	[ChannelName] [NVARCHAR](200) NULL,
	[IsDeleted] [BIT] NULL,
	[CreatedDate] [DATETIME] NULL,
	CONSTRAINT [PK_AffMediaChanel] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC,
		[ChannelCode] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffMediaChannel] ADD  CONSTRAINT [DF_AffMediaChanel_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[AffMediaChannel] ADD  CONSTRAINT [DF_AffMediaChanel_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO


/****** Object:  Table [dbo].[AffMediaLink] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMediaLink](
	[AffId] [INT] NOT NULL,
	[ChannelCode] [VARCHAR](50) NOT NULL,
	[LanguageCode] [VARCHAR](10) NULL,
	[AffMediaLink] [VARCHAR](500) NOT NULL,
	[IsShow] [BIT] NULL
) ON [SettingData]
GO
--
SET ANSI_PADDING ON
GO
CREATE CLUSTERED INDEX [CIX_AffMediaLink] ON [dbo].[AffMediaLink]
(
	[AffId] ASC,
	[ChannelCode] ASC,
	[LanguageCode] ASC,
	[AffMediaLink] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffMediaLink] ADD  CONSTRAINT [DF_AffMediaLink_IsShow]  DEFAULT ((1)) FOR [IsShow]
GO


/****** Object:  Table [dbo].[AffMemberPolicy] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffMemberPolicy](
	[CustId] [INT] NOT NULL,
	[FuncId] [INT] NOT NULL,
	[Policy] [TINYINT] NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	CONSTRAINT [PK_AffMemberPolicy] PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC,
		[FuncId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_AffMemberPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_AffMemberPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO


/****** Object:  Table [dbo].[AffPayout] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffPayout](
	[RefId] [BIGINT] IDENTITY(2000000001,1) NOT NULL,
	[AffId] [INT] NULL,
	[Amount] [MONEY] NULL,
	[AffPayout] [MONEY] NULL,
	[AffCurrency] [INT] NULL,
	[TransDate] [DATETIME] NULL,
	[CompletedDate] [DATETIME] NULL,
	[Status] [VARCHAR](50) NULL,
	[AdminDesc] [NVARCHAR](300) NULL,
	[AffDesc] [NVARCHAR](300) NULL,
	[PreferredPayment] [VARCHAR](20) NULL,
	[Player_Username] [VARCHAR](30) NULL,
	[Player_Currency] [INT] NULL,
	[Player_CurrencyName] [NVARCHAR](50) NULL,
	[Player_CurrencyCode] [VARCHAR](3) NULL,
	[Player_CustId] [INT] NULL,
	[AffRate] [FLOAT] NULL,
	CONSTRAINT [PK_AffPayout] PRIMARY KEY NONCLUSTERED 
	(
		[RefId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
) ON [TransactionData]
GO
--
CREATE CLUSTERED INDEX [CIX_AffId] ON [dbo].[AffPayout]
(
	[AffId] ASC,
	[TransDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO
-- 
CREATE NONCLUSTERED INDEX [IX_TransDate] ON [dbo].[AffPayout]
(
	[TransDate] ASC
)
INCLUDE([Amount]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [TransactionIndex]
GO


/****** Object:  Table [dbo].[AffType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffType](
	[TypeId] [TINYINT] NOT NULL,
	[Name] [NVARCHAR](100) NULL,
	[Description] [NVARCHAR](250) NULL,
	[CreatedDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[IsShown] [BIT] NULL,
	CONSTRAINT [PK_AffType] PRIMARY KEY CLUSTERED 
	(
		[TypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AffData]
) ON [AffData]
GO
--
ALTER TABLE [dbo].[AffType] ADD  CONSTRAINT [DF_AffType_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[AffType] ADD  CONSTRAINT [DF_AffType_IsShown]  DEFAULT ((0)) FOR [IsShown]
GO


/****** Object:  Table [dbo].[AffUserLoginInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffUserLoginInfo](
	[AffId] [INT] NOT NULL,
	[IP] [NVARCHAR](25) NOT NULL,
	[DeviceInfo] [NVARCHAR](100) NOT NULL,
	[FailedLoginCount] [TINYINT] NULL,
	[LastLoginDate] [DATETIME] NULL,
	[VerificationCount] [TINYINT] NULL,
	[LastVerificationDate] [DATETIME] NULL,
	CONSTRAINT [PK_AffUserLoginInfo] PRIMARY KEY CLUSTERED 
	(
		[AffId] ASC,
		[IP] ASC,
		[DeviceInfo] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[ClickStatistics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatistics](
	[ClickId] [BIGINT] IDENTITY(1,1) NOT NULL,
	[AffId] [INT] NOT NULL,
	[UpdatedTime] [DATETIME] NOT NULL,
	[IP] [VARCHAR](25) NOT NULL,
	[Date] [SMALLDATETIME] NOT NULL,
	[Browser] [NVARCHAR](50) NOT NULL,
	[URLReferrer] [NVARCHAR](300) NOT NULL,
	[DomainReferrer] [NVARCHAR](300) NOT NULL,
	[OS] [NVARCHAR](50) NULL,
	[Device] [NVARCHAR](50) NULL,
	[BrowserVersion] [NVARCHAR](16) NULL,
	[BrowserResolution] [NVARCHAR](16) NULL,
	[BrowserLanguage] [NVARCHAR](8) NULL,
	[UserAgent] [NVARCHAR](256) NULL,
	[Country] [NVARCHAR](256) NULL,
	[LanguageCode] [VARCHAR](10) NULL,
	[SportCode] [VARCHAR](50) NULL,
	[RedirectURL] [NVARCHAR](256) NULL,
	[Status] [TINYINT] NULL,
	[DeviceType] [TINYINT] NULL,
	[AffMediaLink] [VARCHAR](500) NULL,
	CONSTRAINT [PK_ClickStatistics] PRIMARY KEY NONCLUSTERED 
	(
		[ClickId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [StatIndex]
) ON [StatData]
GO
--
CREATE CLUSTERED INDEX [CIX_AffId_Date] ON [dbo].[ClickStatistics]
(
	[AffId] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [StatIndex]
GO
--
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_Status]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[ClickStatistics] ADD  CONSTRAINT [DF_ClickStatistics_DeviceType]  DEFAULT ((0)) FOR [DeviceType]
GO


/****** Object:  Table [dbo].[ClickStatistics_bk] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatistics_bk](
	[ClickId] [BIGINT] NOT NULL,
	[AffId] [INT] NOT NULL,
	[UpdatedTime] [DATETIME] NOT NULL,
	[IP] [VARCHAR](25) NOT NULL,
	[Date] [SMALLDATETIME] NOT NULL,
	[Browser] [NVARCHAR](50) NOT NULL,
	[URLReferrer] [NVARCHAR](300) NOT NULL,
	[DomainReferrer] [NVARCHAR](300) NOT NULL,
	[OS] [NVARCHAR](50) NULL,
	[Device] [NVARCHAR](50) NULL,
	[BrowserVersion] [NVARCHAR](16) NULL,
	[BrowserResolution] [NVARCHAR](16) NULL,
	[BrowserLanguage] [NVARCHAR](8) NULL,
	[UserAgent] [NVARCHAR](256) NULL,
	[Country] [NVARCHAR](256) NULL,
	[LanguageCode] [VARCHAR](10) NULL,
	[SportCode] [VARCHAR](50) NULL,
	[RedirectURL] [NVARCHAR](256) NULL,
	[Status] [TINYINT] NULL,
	[DeviceType] [TINYINT] NULL,
	[AffMediaLink] [VARCHAR](500) NULL,
	CONSTRAINT [PK_ClickStatistics_bk] PRIMARY KEY NONCLUSTERED 
	(
		[ClickId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [INDEX]
) ON [ClickStatistics_Scheme]([Date])
GO
--
CREATE CLUSTERED INDEX [CIX_Date_AffId] ON [dbo].[ClickStatistics_bk]
(
	[Date] ASC,
	[AffId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ClickStatistics_Scheme]([Date])
GO


/****** Object:  Table [dbo].[ClickStatisticsSum] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClickStatisticsSum](
	[AffId] [INT] NOT NULL,
	[DomainReferrer] [NVARCHAR](300) NOT NULL,
	[Date] [SMALLDATETIME] NOT NULL,
	[LanguageCode] [VARCHAR](10) NOT NULL,
	[SportCode] [VARCHAR](50) NOT NULL,
	[DeviceType] [TINYINT] NOT NULL,
	[TotalClick] [INT] NULL,
	[UniqueClick] [INT] NULL,
	[TotalSignup] [INT] NULL,
	[TotalDeposit] [INT] NULL,
	CONSTRAINT [PK_ClickStatisticsSum] PRIMARY KEY CLUSTERED 
	(
		[Date] ASC,
		[AffId] ASC,
		[DomainReferrer] ASC,
		[SportCode] ASC,
		[LanguageCode] ASC,
		[DeviceType] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ClickStatisticsSum_Scheme]([Date])
) ON [ClickStatisticsSum_Scheme]([Date])
GO


/****** Object:  Table [dbo].[CommGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroup](
	[GroupId] [INT] IDENTITY(1,1) NOT NULL,
	[GroupName] [NVARCHAR](100) NULL,
	[Description] [NVARCHAR](100) NULL,
	[Creator] [INT] NULL,
	[CreatedDate] [DATETIME] NULL,
	[IsPrivate] [BIT] NULL,
	[IsDeleted] [BIT] NULL,
	[SubCommRate] [DECIMAL](9, 8) NULL,
	[GroupTypeId] [INT] NOT NULL,
	[QMTurnover] [MONEY] NULL,
	CONSTRAINT [PK_CommGroup] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[CommGroup] ADD CONSTRAINT [DF_CommGroup_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[CommGroup] ADD CONSTRAINT [DF_CommGroup_IsPrivate]  DEFAULT ((0)) FOR [IsPrivate]
GO
ALTER TABLE [dbo].[CommGroup] ADD CONSTRAINT [DF_CommGroup_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[CommGroup] ADD CONSTRAINT [DF_CommGroup_GroupTypeId]  DEFAULT ((1)) FOR [GroupTypeId]
GO
ALTER TABLE [dbo].[CommGroup] ADD CONSTRAINT [DF_CommGroup_QMTurnover]  DEFAULT ((0)) FOR [QMTurnover]
GO


/****** Object:  Table [dbo].[CommGroupHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommGroupHistory](
	[MonthDate] [DATETIME] NOT NULL,
	[GroupId] [INT] NOT NULL,
	[SubCommRate] [DECIMAL](9, 8) NULL,
	[QMTurnover] [MONEY] NULL,
	CONSTRAINT [PK_CommGroupHistory] PRIMARY KEY CLUSTERED 
	(
		[MonthDate] ASC,
		[GroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[CommGroupHistory] ADD CONSTRAINT [DF_CommGroupHistory_QMTurnover]  DEFAULT ((0)) FOR [QMTurnover]
GO


/****** Object:  Table [dbo].[Deductions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Deductions](
	[DeductionId] [TINYINT] NOT NULL,
	[DeductionName] [VARCHAR](50) NULL,
	[DeductedPercentage] [DECIMAL](9, 8) NULL,
	[IsTest] [BIT] NULL,
	[IsDeleted] [BIT] NULL,
	[DeductedAmount] [MONEY] NULL,
	[IsDeductedPercent] [BIT] NULL,
	[Commission] [DECIMAL](9, 8) NULL,
	CONSTRAINT [PK_Deductions] PRIMARY KEY CLUSTERED 
	(
		[DeductionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_IsTest]  DEFAULT ((0)) FOR [IsTest]
GO
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[Deductions] ADD  CONSTRAINT [DF_Deductions_Commission]  DEFAULT ((0)) FOR [Commission]
GO


/****** Object:  Table [dbo].[DeductionSetting] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSetting](
	[GroupId] [INT] NOT NULL,
	[DeductionId] [TINYINT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[GroupProductId] [INT] NULL,
	[DeductedPercentage] [DECIMAL](9, 8) NULL,
	[DeductedAmount] [MONEY] NULL,
	[IsDeductedPercent] [BIT] NULL,
	CONSTRAINT [PK_DeductionSetting] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[DeductionId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[DeductionSettingHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeductionSettingHistory](
	[GroupId] [INT] NOT NULL,
	[MonthDate] [DATETIME] NOT NULL,
	[DeductionId] [TINYINT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[GroupProductId] [INT] NULL,
	[DeductedPercentage] [DECIMAL](9, 8) NULL,
	[DeductedAmount] [MONEY] NULL,
	[IsDeductedPercent] [BIT] NULL,
	CONSTRAINT [PK_DeductionSettingHistory] PRIMARY KEY NONCLUSTERED 
	(
		[GroupId] ASC,
		[MonthDate] ASC,
		[DeductionId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
CREATE CLUSTERED INDEX [CIX_MonthDate_GroupId] ON [dbo].[DeductionSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC,
	[DeductionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO


/****** Object:  Table [dbo].[DomainControl] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DomainControl](
	[Id] [INT] IDENTITY(1,1) NOT NULL,
	[AffDomainId] [INT] NOT NULL,
	[LicenseeDomainId] [INT] NOT NULL,
	[MarketId] [NVARCHAR](10) NOT NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[Status] [BIT] NULL,
	[DeviceType] [TINYINT] NULL,
	[IsDeleted] [BIT] NULL,
	CONSTRAINT [PK_DomainControl] PRIMARY KEY NONCLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
CREATE CLUSTERED INDEX [CIX_AffDomainId_LicenseeDomainId] ON [dbo].[DomainControl]
(
	[AffDomainId] ASC,
	[LicenseeDomainId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO
--
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_DeviceType]  DEFAULT ((0)) FOR [DeviceType]
GO
ALTER TABLE [dbo].[DomainControl] ADD  CONSTRAINT [DF_DomainControl_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO


/****** Object:  Table [dbo].[EmailHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailHistory](
	[MId] [INT] IDENTITY(1,1) NOT NULL,
	[Content] [NVARCHAR](4000) NULL,
	[Sender] [NVARCHAR](100) NULL,
	[Creator] [INT] NULL,
	[AffId] [INT] NULL,
	[AffName] [VARCHAR](30) NULL,
	[Email] [NVARCHAR](50) NULL,
	[Subject] [NVARCHAR](2000) NULL,
	[CreatedDate] [DATETIME] NULL,
	[IP] [VARCHAR](25) NULL,
	[Browser] [NVARCHAR](100) NULL,
	[SessionId] [VARCHAR](200) NULL,
	[IsDeleted] [BIT] NULL,
	CONSTRAINT [PK_EmailHistory] PRIMARY KEY CLUSTERED 
	(
		[MId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [INDEX]
) ON [AffData]
GO
--
ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_EmailHistory_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[EmailHistory] ADD  CONSTRAINT [DF_EmailHistory_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
--
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_AffName] ON [dbo].[EmailHistory]
(
	[AffName] ASC,
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [INDEX]
GO


/****** Object:  Table [dbo].[Exchange] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Exchange](
	[ExchangeId] [INT] NOT NULL,
	[Code] [VARCHAR](5) NULL,
	[MultipliedBy] [INT] NULL,
	CONSTRAINT [PK_Exchange] PRIMARY KEY CLUSTERED 
	(
		[ExchangeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[Exchange] ADD  CONSTRAINT [DF_Exchange_MultipliedBy]  DEFAULT ((0)) FOR [MultipliedBy]
GO


/****** Object:  Table [dbo].[IPv4Addresses] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[IPv4Addresses](
	[From] [BIGINT] NOT NULL,
	[To] [BIGINT] NOT NULL,
	[Code2] [NCHAR](2) NOT NULL,
	[Code3] [NCHAR](3) NOT NULL,
	[Country] [NVARCHAR](64) NOT NULL
) ON [SettingData]
GO


/****** Object:  Table [dbo].[LandingPage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LandingPage](
	[PageId] [SMALLINT] IDENTITY(1,1) NOT NULL,
	[PageName] [NVARCHAR](200) NULL,
	[PageCode] [NVARCHAR](100) NULL,
	[IsDeleted] [BIT] NULL,
	CONSTRAINT [PK_LandingPage] PRIMARY KEY CLUSTERED 
	(
		[PageId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[LandingPage] ADD  CONSTRAINT [DF_LandingPage_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO


/****** Object:  Table [dbo].[LicenseeDomain] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LicenseeDomain](
	[DomainId] [INT] IDENTITY(1,1) NOT NULL,
	[DomainName] [NVARCHAR](50) NOT NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[DeviceType] [TINYINT] NULL,
	[IsDeleted] [BIT] NULL,
	[W3Prefix] [VARCHAR](30) NULL,
	[IsSSL] [BIT] NULL,
	CONSTRAINT [PK_LicenseeDomain] PRIMARY KEY CLUSTERED 
	(
		[DomainId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
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


/****** Object:  Table [dbo].[LogAction] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogAction](
	[ActionId] [INT] NOT NULL,
	[ActionTypeId] [INT] NULL,
	[SPName] [VARCHAR](200) NULL,
	[Description] [NVARCHAR](4000) NULL,
	CONSTRAINT [PK_LogAction] PRIMARY KEY NONCLUSTERED 
	(
		[ActionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData]
GO
--
SET ANSI_PADDING ON
GO
CREATE CLUSTERED INDEX [CIX_SPName] ON [dbo].[LogAction]
(
	[SPName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO


/****** Object:  Table [dbo].[LogType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LogType](
	[TypeId] [SMALLINT] NOT NULL,
	[TypeName] [NVARCHAR](50) NULL,
	[Description] [NVARCHAR](50) NULL,
	CONSTRAINT [PK_LogType] PRIMARY KEY CLUSTERED 
	(
		[TypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData]
GO


/****** Object:  Table [dbo].[Market] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Market](
	[MarketId] [NVARCHAR](10) NOT NULL,
	[MarketName] [NVARCHAR](50) NULL,
	[MarketNativeName] [NVARCHAR](50) NULL,
	[ShortedCode] [NVARCHAR](10) NULL,
	[DisplayName] [NVARCHAR](50) NULL,
	CONSTRAINT [PK_Market] PRIMARY KEY CLUSTERED 
	(
		[MarketId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[MediaGallery] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MediaGallery](
	[MediaId] [INT] IDENTITY(1,1) NOT NULL,
	[FileName] [NVARCHAR](200) NOT NULL,
	[TargetId] [TINYINT] NULL,
	[ImageType] [VARCHAR](10) NULL,
	[Message] [NVARCHAR](MAX) NULL,
	[Size] [VARCHAR](20) NULL,
	[Categories] [VARCHAR](2000) NULL,
	[SubCategories] [VARCHAR](2000) NULL,
	[Language] [VARCHAR](100) NULL,
	[Currencies] [VARCHAR](500) NULL,
	[AffTypes] [VARCHAR](20) NULL,
	[DeviceTypes] [VARCHAR](10) NULL,
	[Creator] [INT] NULL,
	[CreatedDate] [DATETIME] NULL,
	[UpdatedBy] [INT] NULL,
	[UpdatedDate] [DATETIME] NULL,
	CONSTRAINT [PK_MediaGallery] PRIMARY KEY NONCLUSTERED 
	(
		[MediaId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData] TEXTIMAGE_ON [SettingData]
GO
--
ALTER TABLE [dbo].[MediaGallery] ADD  CONSTRAINT [DF_MediaGallery_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO


/****** Object:  Table [dbo].[MemberClickDetail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberClickDetail](
	[CustId] [INT] NOT NULL,
	[ClickId] [BIGINT] NOT NULL,
	[DomainReferrer] [NVARCHAR](300) NULL,
	[IBCCustId] [INT] NULL,
	[LanguageCode] [VARCHAR](10) NULL,
	[SportCode] [VARCHAR](50) NULL,
	[URLRedirect] [NVARCHAR](300) NULL,
	[URLReferrer] [NVARCHAR](300) NULL,
	[DeviceType] [TINYINT] NULL,
	[AffID] [INT] NULL,
	[CreatedDate] [DATETIME] NULL,
	CONSTRAINT [PK_MemberClickDetail] PRIMARY KEY NONCLUSTERED 
	(
		[CustId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
) ON [AccInfoData]
GO
--
CREATE CLUSTERED INDEX [IX_CreatedDate] ON [dbo].[MemberClickDetail]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
--
CREATE NONCLUSTERED INDEX [IX_AffId] ON [dbo].[MemberClickDetail]
(
	[AffID] ASC
)
INCLUDE([LanguageCode],[SportCode],[DeviceType]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO


/****** Object:  Table [dbo].[MemberInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberInfo](
	[CustId] [INT] NOT NULL,
	[UserName] [VARCHAR](30) NOT NULL,
	[FirstName] [NVARCHAR](50) NULL,
	[LastName] [NVARCHAR](50) NULL,
	[Email] [NVARCHAR](50) NULL,
	[Currency] [INT] NULL,
	[ActStatus] [TINYINT] NULL,
	[Status] [TINYINT] NULL,
	[RegisteredDate] [DATETIME] NULL,
	[AffId] [INT] NOT NULL,
	[IBCCustId] [INT] NULL,
	[IBCUserName] [VARCHAR](30) NULL,
	[CreatedDate] [DATETIME] NULL,
	[IsRemoved] [BIT] NULL,
	[Recommend] [INT] NULL,
	[ClickId] [BIGINT] NULL,
	[FirstDepositDate] [DATETIME] NULL,
	[FirstDepositAmount] [MONEY] NULL,
	CONSTRAINT [PK_MemberInfo] PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
) ON [AccInfoData]
GO
--
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_IsRemoved]  DEFAULT ((0)) FOR [IsRemoved]
GO
ALTER TABLE [dbo].[MemberInfo] ADD  CONSTRAINT [DF_MemberInfo_ClickId]  DEFAULT ((0)) FOR [ClickId]
GO
--
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_AffId] ON [dbo].[MemberInfo]
(
	[AffId] ASC,
	[IBCCustId] ASC
)
INCLUDE([UserName],[IBCUserName],[Currency],[FirstName],[LastName],[Email],[RegisteredDate],[CreatedDate],[IsRemoved]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_MemberInfo_AffID] ON [dbo].[MemberInfo]
(
	[AffID] ASC,
	[IsRemoved] ASC
)
INCLUDE([UserName],[IBCUserName],[IBCCustID],[CreatedDate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_MemberInfo_IBCUserName] ON [dbo].[MemberInfo]
(
	[IBCUserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX_MemberInfo_UserName] ON [dbo].[MemberInfo]
(
	[UserName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 85, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO


/****** Object:  Table [dbo].[MemberRemoval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MemberRemoval](
	[CustId] [INT] NOT NULL,
	[RemovedDate] [DATETIME] NOT NULL,
	[RemovedBy] [INT] NULL,
	[FromDate] [SMALLDATETIME] NULL,
	[ToDate] [SMALLDATETIME] NULL,
	[IsInclude] [BIT] NULL,
	CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED 
	(
		[CustId] ASC,
		[RemovedDate] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
) ON [AccInfoData]
GO
--
CREATE NONCLUSTERED INDEX [Ix_CustId_FromDate_ToDate] ON [dbo].[MemberRemoval]
(
	[CustId] ASC,
	[FromDate] ASC,
	[ToDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [AccInfoIndex]
GO


/****** Object:  Table [dbo].[Messages] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Messages](
	[MessageId] [INT] NOT NULL,
	[MessageTypeId] [SMALLINT] NULL,
	[Description] [NVARCHAR](2000) NULL,
	[MessageContentBN] [NVARCHAR](4000) NULL,
	[MessageContentENEURO] [NVARCHAR](2000) NULL,
	[MessageContentEN] [NVARCHAR](2000) NULL,
	[MessageContentHI] [NVARCHAR](2000) NULL,
	[MessageContentHIEN] [NVARCHAR](2000) NULL,
	[MessageContentID] [NVARCHAR](2000) NULL,
	[MessageContentJP] [NVARCHAR](2000) NULL,
	[MessageContentKH] [NVARCHAR](4000) NULL,
	[MessageContentKO] [NVARCHAR](2000) NULL,
	[MessageContentHITG] [NVARCHAR](2000) NULL,
	[MessageContentTH] [NVARCHAR](2000) NULL,
	[MessageContentVN] [NVARCHAR](2000) NULL,
	[MessageContentCS] [NVARCHAR](2000) NULL,
	[MessageContentCH] [NVARCHAR](2000) NULL,
	CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED 
	(
		[MessageId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[News] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[News](
	[MsgId] [INT] IDENTITY(1,1) NOT NULL,
	[Message_En] [NVARCHAR](4000) NULL,
	[Message_Cn] [NVARCHAR](4000) NULL,
	[Message_Tw] [NVARCHAR](4000) NULL,
	[Message_Es] [NVARCHAR](4000) NULL,
	[Message_Th] [NVARCHAR](4000) NULL,
	[Message_Id] [NVARCHAR](4000) NULL,
	[Message_Vi] [NVARCHAR](4000) NULL,
	[Message_Kr] [NVARCHAR](4000) NULL,
	[Message_Jp] [NVARCHAR](4000) NULL,
	[Creator] [INT] NULL,
	[PostedDate] [DATETIME] NULL,
	[Important] [BIT] NOT NULL,
	[UpdatedBy] [INT] NULL,
	[UpdatedDate] [DATETIME] NULL,
	[Message_Hi] [NVARCHAR](4000) NULL,
	[Message_Ms] [NVARCHAR](4000) NULL,
	[Message_Kh] [NVARCHAR](4000) NULL,
	[Message_Bn] [NVARCHAR](4000) NULL,
	CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED 
	(
		[MsgId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[News] ADD  CONSTRAINT [DF_News_Important]  DEFAULT ((0)) FOR [Important]
GO


/****** Object:  Table [dbo].[On_User] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[On_User](
	[On_UserId] [INT] IDENTITY(1,1) NOT NULL,
	[On_SessionId] [INT] NOT NULL,
	[CustId] [INT] NULL,
	[Reload_Time] [DATETIME] NULL,
	[ServerId] [INT] NULL,
	[IP] [NVARCHAR](20) NULL,
	[IsKickedOut] [BIT] NULL,
	[SubAccId] [INT] NULL,
	[NetSessionId] [VARCHAR](30) NULL,
	[Country] [SMALLINT] NULL,
	[MachineIP] [INT] NULL,
	[DomainId] [INT] NULL,
	CONSTRAINT [PK_On_User] PRIMARY KEY CLUSTERED 
	(
		[On_UserId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[Products] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Products](
	[ProductId] [INT] NOT NULL,
	[ProductName] [VARCHAR](100) NOT NULL,
	[ProductPrefix] [VARCHAR](10) NULL,
	[IsIBC] [BIT] NULL,
	[Enabled] [BIT] NULL,
	[IsTest] [BIT] NULL,
	[EndOfSupportDate] [SMALLDATETIME] NULL,
	[ReleasedDate] [SMALLDATETIME] NULL,
	[RefProductId] [INT] NULL,
	[DataSource] [VARCHAR](100) NULL,
	[IsP2P] [BIT] NULL,
	CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
	(
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_IsTest]  DEFAULT ((0)) FOR [IsTest]
GO
ALTER TABLE [dbo].[Products] ADD  CONSTRAINT [DF_Products_IsP2P]  DEFAULT ((0)) FOR [IsP2P]
GO


/****** Object:  Table [dbo].[rptAffCommission] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffCommission](
	[MonthDate] [SMALLDATETIME] NOT NULL,
	[AffId] [INT] NOT NULL,
	[GroupId] [INT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[Deposit] [MONEY] NULL,
	[Withdrawal] [MONEY] NULL,
	[Bonus] [MONEY] NULL,
	[Adjustment] [MONEY] NULL,
	[Turnover] [MONEY] NULL,
	[Winloss] [MONEY] NULL,
	[GrossWinloss] [MONEY] NULL,
	[NetWinloss] [MONEY] NULL,
	[NetTurnover] [MONEY] NULL,
	[ActivePlayer] [INT] NULL,
	[QualifiedMember] [INT] NULL,
	[CommissionRate] [DECIMAL](9, 8) NULL,
	[Rebate] [MONEY] NULL,
	[Revenue] [MONEY] NULL,
	[P2PFee] [MONEY] NULL,
	[PlatFormFee] [MONEY] NULL,
	[OperationalFee] [MONEY] NULL,
	[DepositFee] [MONEY] NULL,
	[WithdrawalFee] [MONEY] NULL,
	CONSTRAINT [PK_rptAffCommission] PRIMARY KEY CLUSTERED 
	(
		[MonthDate] ASC,
		[AffId] ASC,
		[GroupId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
--
CREATE NONCLUSTERED INDEX [IX_AffId_GroupId_ProductId] ON [dbo].[rptAffCommission]
(
	[AffId] ASC,
	[GroupId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO


/****** Object:  Table [dbo].[rptAffCommissionDetail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffCommissionDetail](
	[MonthDate] [SMALLDATETIME] NOT NULL,
	[AffId] [INT] NOT NULL,
	[GroupId] [INT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[Deposit] [MONEY] NULL,
	[Withdrawal] [MONEY] NULL,
	[Bonus] [MONEY] NULL,
	[Adjustment] [MONEY] NULL,
	[Turnover] [MONEY] NULL,
	[Winloss] [MONEY] NULL,
	[GrossWinloss] [MONEY] NULL,
	[NetWinloss] [MONEY] NULL,
	[NetTurnover] [MONEY] NULL,
	[ActivePlayer] [INT] NULL,
	[QualifiedMember] [INT] NULL,
	[CommissionRate] [DECIMAL](9, 8) NULL,
	[Rebate] [MONEY] NULL,
	[Revenue] [MONEY] NULL,
	[P2PFee] [MONEY] NULL,
	[PlatFormFee] [MONEY] NULL,
	[OperationalFee] [MONEY] NULL,
	[DepositFee] [MONEY] NULL,
	[WithdrawalFee] [MONEY] NULL,
	[GroupProductId] [TINYINT] NOT NULL,
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


/****** Object:  Table [dbo].[rptAffMonthly] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptAffMonthly](
	[MonthDate] [SMALLDATETIME] NOT NULL,
	[AffId] [INT] NOT NULL,
	[GroupId] [INT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[Turnover] [MONEY] NULL,
	[Winloss] [MONEY] NULL,
	[Revenue] [MONEY] NULL,
	CONSTRAINT [PK_rptAffMonthly] PRIMARY KEY CLUSTERED 
	(
		[MonthDate] ASC,
		[AffId] ASC,
		[GroupId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO


/****** Object:  Table [dbo].[rptMemberDaily] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[rptMemberDaily](
	[WinlostDate] [SMALLDATETIME] NOT NULL,
	[AffId] [INT] NULL,
	[CustId] [INT] NOT NULL,
	[Currency] [INT] NULL,
	[ExRate] [FLOAT] NULL,
	[AffExRate] [FLOAT] NULL,
	[ProductId] [INT] NOT NULL,
	[Deposit] [MONEY] NULL,
	[Withdrawal] [MONEY] NULL,
	[Bonus] [MONEY] NULL,
	[Adjustment] [MONEY] NULL,
	[Turnover] [MONEY] NULL,
	[Winloss] [MONEY] NULL,
	[Rebate] [MONEY] NULL,
	[Revenue] [MONEY] NULL,
	[ProgressiveBet] [MONEY] NULL,
	[ProgressiveWin] [MONEY] NULL,
	CONSTRAINT [PK_rptMemberDaily] PRIMARY KEY NONCLUSTERED 
	(
		[WinlostDate] ASC,
		[CustId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
--
CREATE CLUSTERED INDEX [CIX_WinlostDate_AffId_ProductId] ON [dbo].[rptMemberDaily]
(
	[WinlostDate] ASC,
	[AffId] ASC,
	[ProductId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
--
CREATE NONCLUSTERED INDEX [IX_AffId_ProductId] ON [dbo].[rptMemberDaily]
(
	[AffId] ASC,
	[ProductId] ASC
)
INCLUDE([Deposit],[Withdrawal],[Bonus],[Adjustment],[Turnover],[Winloss],[AffExRate]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO


/****** Object:  Table [dbo].[StraightSetting] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StraightSetting](
	[GroupId] [INT] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[GroupProductId] [INT] NULL,
	[DeductedPercentage] [DECIMAL](9, 8) NULL,
	[Commission] [DECIMAL](9, 8) NULL,
	CONSTRAINT [PK_StraightSetting] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[StraightSettingHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StraightSettingHistory](
	[GroupId] [INT] NOT NULL,
	[MonthDate] [DATETIME] NOT NULL,
	[ProductId] [INT] NOT NULL,
	[GroupProductId] [INT] NULL,
	[DeductedPercentage] [DECIMAL](9, 8) NULL,
	[Commission] [DECIMAL](9, 8) NULL,
	CONSTRAINT [PK_StraightSettingHistory] PRIMARY KEY NONCLUSTERED 
	(
		[GroupId] ASC,
		[MonthDate] ASC,
		[ProductId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
CREATE CLUSTERED INDEX [CIX_StraightSettingHistory] ON [dbo].[StraightSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO


/****** Object:  Table [dbo].[SubAffDomain] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SubAffDomain](
	[DomainId] [INT] IDENTITY(1,1) NOT NULL,
	[DomainName] [NVARCHAR](50) NOT NULL,
	[CreateDate] [DATETIME] NULL,
	[ModifyDate] [DATETIME] NULL,
	[Creator] [INT] NULL,
	[IsDeleted] [BIT] NULL,
	[IsSSL] [BIT] NULL,
	CONSTRAINT [PK_SubAffDomain] PRIMARY KEY CLUSTERED 
	(
		[DomainId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO
ALTER TABLE [dbo].[SubAffDomain] ADD  CONSTRAINT [DF_SubAffDomain_IsSSL]  DEFAULT ((0)) FOR [IsSSL]
GO


/****** Object:  Table [dbo].[TierSetting] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TierSetting](
	[GroupId] [INT] NOT NULL,
	[TierId] [INT] NOT NULL,
	[MinAmount] [MONEY] NULL,
	[MaxAmount] [MONEY] NULL,
	[MinAM] [INT] NULL,
	[MaxAM] [INT] NULL,
	[Commission] [DECIMAL](9, 8) NULL,
	[GroupProductId] [TINYINT] NOT NULL,
	[IsActivePlayerSum] [BIT] NULL,
	[MinQM] [INT] NULL,
	[MaxQM] [INT] NULL,
	CONSTRAINT [PK_TierSetting] PRIMARY KEY CLUSTERED 
	(
		[GroupId] ASC,
		[GroupProductId] ASC,
		[TierId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[TierSettingHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TierSettingHistory](
	[GroupId] [INT] NOT NULL,
	[MonthDate] [DATETIME] NOT NULL,
	[TierId] [INT] NOT NULL,
	[MinAmount] [MONEY] NULL,
	[MaxAmount] [MONEY] NULL,
	[MinAM] [INT] NULL,
	[MaxAM] [INT] NULL,
	[Commission] [DECIMAL](9, 8) NULL,
	[GroupProductId] [TINYINT] NOT NULL,
	[IsActivePlayerSum] [BIT] NULL,
	[MinQM] [INT] NULL,
	[MaxQM] [INT] NULL,
	CONSTRAINT [PK_TierSettingHistory] PRIMARY KEY NONCLUSTERED 
	(
		[GroupId] ASC,
		[MonthDate] ASC,
		[GroupProductId] ASC,
		[TierId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
--
CREATE CLUSTERED INDEX [CIX_MonthDate_GroupId] ON [dbo].[TierSettingHistory]
(
	[MonthDate] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
GO


/****** Object:  Table [dbo].[TransferBalanceHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransferBalanceHistory](
	[TransId] [BIGINT] IDENTITY(1000,1) NOT NULL,
	[TransTime] [DATETIME] NULL,
	[TransDate] [DATETIME] NULL,
	[Status] [VARCHAR](20) NULL,
	[AffId] [INT] NULL,
	[AffUserName] [VARCHAR](50) NULL,
	[Player_CustId] [INT] NULL,
	[Player_UserName] [VARCHAR](50) NULL,
	[Player_Currency] [INT] NULL,
	[Player_CurrencyCode] [VARCHAR](3) NULL,
	[CustId] [INT] NULL,
	[UserName] [VARCHAR](50) NULL,
	[Currency] [INT] NULL,
	[CurrencyCode] [VARCHAR](3) NULL,
	[Amount] [MONEY] NULL,
	[ExRate] [FLOAT] NULL,
	[LastSyncTime] [DATETIME] NULL,
	[SyncCount] [TINYINT] NULL,
	[SyncLog] [VARCHAR](300) NULL,
	CONSTRAINT [PK_TransferBalanceHistory] PRIMARY KEY NONCLUSTERED 
	(
		[TransId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
) ON [ReportData]
GO
--
CREATE CLUSTERED INDEX [CIX_TransferBalanceHistory] ON [dbo].[TransferBalanceHistory]
(
	[TransDate] ASC,
	[AffId] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO


/****** Object:  Table [dbo].[TransType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransType](
	[TypeId] [SMALLINT] NOT NULL,
	[TypeName] [NVARCHAR](50) NULL,
	[TypeDesc] [NVARCHAR](50) NULL,
	CONSTRAINT [PK_TransType] PRIMARY KEY CLUSTERED 
	(
		[TypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[UserLog_RunSP_Detail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserLog_RunSP_Detail](
	[LogId] [INT] IDENTITY(1,1) NOT NULL,
	[LogTypeId] [INT] NULL,
	[LogActionId] [INT] NULL,
	[SPName] [VARCHAR](200) NULL,
	[UserId] [INT] NULL,
	[AffId] [INT] NULL,
	[LogDate] [DATETIME] NOT NULL,
	[OldData] [NVARCHAR](MAX) NULL,
	[NewData] [NVARCHAR](MAX) NULL,
	[IP] [VARCHAR](50) NULL,
	[Language] [VARCHAR](20) NULL,
	[IsWebCall] [BIT] NULL,
	CONSTRAINT [PK_UserLog_RunSP_Detail] PRIMARY KEY NONCLUSTERED 
	(
		[LogId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
) ON [LogData] TEXTIMAGE_ON [LogData]
GO
--
CREATE CLUSTERED INDEX [CIX_LogActionId_LogDate] ON [dbo].[UserLog_RunSP_Detail]
(
	[LogActionId] ASC,
	[LogDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO
--
CREATE NONCLUSTERED INDEX [IX_UserId_LogActionId] ON [dbo].[UserLog_RunSP_Detail]
(
	[UserId] ASC,
	[LogActionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [LogData]
GO
--
ALTER TABLE [dbo].[UserLog_RunSP_Detail] ADD  CONSTRAINT [DF_UserLog_RunSP_Detail_LogDate]  DEFAULT (getdate()) FOR [LogDate]
GO


/****** Object:  Table [dbo].[Username_AutoIncrement] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Username_AutoIncrement](
	[Id] [BIGINT] IDENTITY(1,1) NOT NULL,
	[PrefixName] [NVARCHAR](50) NULL,
	[SubfixName] [BIGINT] NULL,
	CONSTRAINT [PK_Username_AutoIncrement] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO


/****** Object:  Table [dbo].[GroupType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupType](
	[GroupTypeId] [INT] IDENTITY(1,1) NOT NULL,
	[GroupTypeBy] [VARCHAR](50) NOT NULL,
	[GroupTypeName] [NVARCHAR](100) NOT NULL,
	[DisplayOrder] [SMALLINT] NOT NULL,
	CONSTRAINT [PK_GroupType] PRIMARY KEY CLUSTERED 
	(
		[GroupTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO