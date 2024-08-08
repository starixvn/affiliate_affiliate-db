/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240808@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for 12Emerald Playtech on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (3, '12Emerald - Playtech', 'PTCS', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (3, 'LastQueueId', '0')
	 , (3, 'LaunchDate', '2013-01-18')
	 , (3, 'SourceTable', 'APIProduct_ImportQueueTest')
GO

-- Drop table
DROP TABLE IF EXISTS bettrans_PlaytechTest
GO

-- New table
CREATE TABLE [dbo].[bettrans_PlaytechTest](
	[IBCCustId] [INT] NOT NULL,
	[Username] [NVARCHAR](50) NOT NULL,
	[GameCode] BIGINT NOT NULL,
	[Bet] [MONEY] NULL,
	[BonusBet] [MONEY] NULL,
	[Winloss] [MONEY] NULL,
	[Currency] [VARCHAR](5) NULL,
	[GameDate] [DATETIME] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_PlaytechTest] PRIMARY KEY NONCLUSTERED 
	(
		[GameCode] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_PlaytechTest_WinlostDate] ON [dbo].[bettrans_PlaytechTest]
(
	[WinlostDate] ASC
) ON [ReportData]
GO