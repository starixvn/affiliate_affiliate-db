USE [Affiliate_12BET]
GO
/****** Object:  Table [dbo].[AffDaily]    Script Date: 03/02/2010 16:52:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AffDaily](
	[AffID] [int] NOT NULL,
	[Currency] [int] NOT NULL,
	[Winlostdate] [smalldatetime] NOT NULL,
	[SportID] [smallint] NOT NULL,
	[ExRate2] [float] NULL,
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
 CONSTRAINT [PK_AffDaily] PRIMARY KEY CLUSTERED 
(
	[AffID] ASC,
	[Currency] ASC,
	[Winlostdate] ASC,
	[SportID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [ReportData]
) ON [ReportData]
