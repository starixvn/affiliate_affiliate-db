/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240925@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for BetSoft on UAT follow old flow [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

-- Drop table
DROP TABLE bettrans_Betsoft2Test
GO

-- New table
CREATE TABLE [dbo].[bettrans_BetsoftTest](
	[IBCCustId] [INT] NOT NULL,
	[Username] [NVARCHAR](50) NOT NULL,
	[GameSessionId] [BIGINT] NOT NULL,
	[GameId] [INT] NOT NULL,
	[PlatForm] [VARCHAR](50) NULL,
	[BetId] [INT] NOT NULL,
	[Amount] [MONEY] NULL,
	[Win] [MONEY] NULL,
	[BetTime] [DATETIME] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	[StartDate] [DATETIME] NULL,
	[EndDate] [DATETIME] NULL,
	CONSTRAINT [PK_bettrans_BetsoftTest] PRIMARY KEY NONCLUSTERED 
	(
		[Username] ASC,
		[GameSessionId] ASC,
		[GameId] ASC,
		[BetId] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_BetsoftTest_WinlostDate] ON [dbo].[bettrans_BetsoftTest]
(
	[WinlostDate] ASC
) ON [ReportData]
GO