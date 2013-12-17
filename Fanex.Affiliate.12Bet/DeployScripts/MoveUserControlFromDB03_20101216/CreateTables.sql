 USE [Affiliate_12BET]
GO

/****** Object:  Table [dbo].[AffFunctionInfo]    Script Date: 12/16/2010 13:02:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[AffFunctionInfo](
	[FuncID] [int] IDENTITY(100000,1) NOT NULL,
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

ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF__Aff_Funct__Modif__3EA9ABCB]  DEFAULT (getdate()) FOR [ModifyDate]
GO

ALTER TABLE [dbo].[AffFunctionInfo] ADD  CONSTRAINT [DF__Aff_Funct__Displ__3F9DD004]  DEFAULT ((7)) FOR [DisplayOrder]
GO

USE [Affiliate_12BET]
GO

/****** Object:  Table [dbo].[AffGroupInfo]    Script Date: 12/16/2010 13:06:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[AffGroupInfo](
	[GroupID] [int] IDENTITY(1000,1) NOT NULL,
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

ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_GroupName]  DEFAULT ('') FOR [GroupName]
GO

ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_GroupDesc]  DEFAULT ('') FOR [GroupDesc]
GO

ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO

ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF_Aff_GroupInfo_DisplayOrder]  DEFAULT ((5)) FOR [DisplayOrder]
GO

ALTER TABLE [dbo].[AffGroupInfo] ADD  CONSTRAINT [DF__Aff_Group__Syste__1BF4A114]  DEFAULT ('AFFILIATE') FOR [System]
GO


USE [Affiliate_12BET]
GO

/****** Object:  Table [dbo].[AffGroupPolicy]    Script Date: 12/16/2010 13:08:01 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [DATA]
) ON [DATA]

GO

ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_Policy]  DEFAULT ((0)) FOR [Policy]
GO

ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO

ALTER TABLE [dbo].[AffGroupPolicy] ADD  CONSTRAINT [DF_Aff_GroupPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO

USE [Affiliate_12BET]
GO

/****** Object:  Table [dbo].[Affiliate_User]    Script Date: 12/16/2010 13:09:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Affiliate_User](
	[custid] [int] IDENTITY(1000000000,1) NOT NULL,
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [DATA]
) ON [DATA]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[Affiliate_User] ADD  CONSTRAINT [DF_Affiliate_User_createdate]  DEFAULT (getdate()) FOR [createdate]
GO




USE [Affiliate_12BET]
GO

/****** Object:  Table [dbo].[AffMemberPolicy]    Script Date: 12/16/2010 13:10:05 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 80) ON [DATA]
) ON [DATA]

GO

ALTER TABLE [dbo].[AffMemberPolicy] ADD  CONSTRAINT [DF_Aff_MemberPolicy_ModifyDate]  DEFAULT (getdate()) FOR [ModifyDate]
GO








