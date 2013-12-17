USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_AffID]    Script Date: 10/28/2009 15:04:29 ******/
CREATE NONCLUSTERED INDEX [IX_AffID] ON [dbo].[AdminNotes] 
(
	[AffID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Report]    Script Date: 10/28/2009 15:05:25 ******/
CREATE NONCLUSTERED INDEX [IX_Report] ON [dbo].[AffCommission] 
(
	[AffID] ASC,
	[SportID] ASC,
	[WinlostDate] ASC
)
INCLUDE ( [Commission],
[HasBonus],
[HasAdjustment],
[HasMarketing],
[HasPSP]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_GroupID]    Script Date: 10/28/2009 15:33:26 ******/
CREATE NONCLUSTERED INDEX [IX_GroupID] ON [dbo].[AffInfo] 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoIndex]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_SearchAff]    Script Date: 10/28/2009 15:33:45 ******/
CREATE NONCLUSTERED INDEX [IX_SearchAff] ON [dbo].[AffInfo] 
(
	[AffID] ASC,
	[Status] ASC,
	[UserName] ASC,
	[Email] ASC,
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_UserName2]    Script Date: 10/28/2009 15:34:21 ******/
CREATE NONCLUSTERED INDEX [IX_UserName2] ON [dbo].[AffInfo] 
(
	[UserName2] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoIndex]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_AffID]    Script Date: 10/28/2009 15:35:24 ******/
CREATE NONCLUSTERED INDEX [IX_AffID] ON [dbo].[AffPayout] 
(
	[AffID] ASC,
	[Status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Report]    Script Date: 10/28/2009 15:35:44 ******/
CREATE NONCLUSTERED INDEX [IX_Report] ON [dbo].[AffPayout] 
(
	[UserName] ASC,
	[TransDate] ASC,
	[Status] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_ReportAff]    Script Date: 10/28/2009 15:42:59 ******/
CREATE NONCLUSTERED INDEX [IX_ReportAff] ON [dbo].[AffTrans] 
(
	[AffID] ASC,
	[Status] ASC,
	[TransType] ASC,
	[CompletedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Report]    Script Date: 10/28/2009 15:43:24 ******/
CREATE NONCLUSTERED INDEX [IX_Report] ON [dbo].[AffTrans] 
(
	[TransDate] ASC,
	[Status] ASC,
	[TransType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_RefID]    Script Date: 10/28/2009 15:43:57 ******/
CREATE NONCLUSTERED INDEX [IX_RefID] ON [dbo].[AffTrans] 
(
	[RefID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TransactionIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Banners]    Script Date: 10/28/2009 15:44:22 ******/
CREATE NONCLUSTERED INDEX [IX_Banners] ON [dbo].[Banners] 
(
	[Category] ASC,
	[Language] ASC,
	[ImageType] ASC,
	[Size] ASC,
	[Currency] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_AffName]    Script Date: 10/28/2009 15:46:42 ******/
CREATE NONCLUSTERED INDEX [IX_AffName] ON [dbo].[EmailHistory] 
(
	[AffName] ASC,
	[CreatedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Email]    Script Date: 10/28/2009 15:46:55 ******/
CREATE NONCLUSTERED INDEX [IX_Email] ON [dbo].[EmailHistory] 
(
	[Email] ASC,
	[CreatedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_EmailHistory]    Script Date: 10/28/2009 15:47:10 ******/
CREATE NONCLUSTERED INDEX [IX_EmailHistory] ON [dbo].[EmailHistory] 
(
	[CreatedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Sender]    Script Date: 10/28/2009 15:47:24 ******/
CREATE NONCLUSTERED INDEX [IX_Sender] ON [dbo].[EmailHistory] 
(
	[Sender] ASC,
	[CreatedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [INDEX]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_Report]    Script Date: 11/10/2009 19:46:14 ******/
CREATE NONCLUSTERED INDEX [IX_Report] ON [dbo].[MemberDaily] 
(
	[AffID] ASC,
	[SportType] ASC,
	[WinlostDate] ASC,
	[Currency] ASC
)
INCLUDE ( [Deposit],
[Bonus],
[Adjustment],
[Turnover],
[Winlost],
[PSP],
[Marketing],
[AWinlost],
[ABonus]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_MemberInfo_AffID]    Script Date: 10/28/2009 15:48:30 ******/
CREATE NONCLUSTERED INDEX [IX_MemberInfo_AffID] ON [dbo].[MemberInfo] 
(
	[AffID] ASC,
	[IsRemoved] ASC
)
INCLUDE ( [UserName],
[IBCUserName]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_MemberInfo_IBCUserName]    Script Date: 10/28/2009 15:48:44 ******/
CREATE NONCLUSTERED INDEX [IX_MemberInfo_IBCUserName] ON [dbo].[MemberInfo] 
(
	[IBCUserName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_MemberInfo_UserName]    Script Date: 10/28/2009 15:48:56 ******/
CREATE NONCLUSTERED INDEX [IX_MemberInfo_UserName] ON [dbo].[MemberInfo] 
(
	[UserName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [AccInfoIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_AffTrackingCode]    Script Date: 10/28/2009 15:49:51 ******/
CREATE NONCLUSTERED INDEX [IX_AffTrackingCode] ON [dbo].[TrackingCode] 
(
	[AffID] ASC,
	[TrackingCode] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [StatIndex]


USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_RefNo]    Script Date: 10/28/2009 15:50:14 ******/
CREATE NONCLUSTERED INDEX [IX_RefNo] ON [dbo].[UserLog] 
(
	[RefNo] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [UserLogIndex]

USE [Affiliate_12BET]
GO
/****** Object:  Index [IX_UserLog]    Script Date: 10/28/2009 15:50:36 ******/
CREATE CLUSTERED INDEX [IX_UserLog] ON [dbo].[UserLog] 
(
	[TypeID] ASC,
	[AffID] ASC,
	[LoggedDate] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [UserLogIndex]



