/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240806@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for 12Crystal GPI on UAT [RedmineId : #207119]
*/

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (12, '12Crystal - GPI', '12GPI', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (12, 'LastQueueId', '0')
	 , (12, 'LaunchDate', '2019-01-01')
	 , (12, 'SourceTable', 'APIProduct_ImportQueueTest')
GO

-- Drop table 
DROP TABLE bettrans_CrystalTest
GO
DROP TABLE IF EXISTS bettrans_Crystal2Test
GO

-- New table
CREATE TABLE [dbo].[bettrans_Crystal2Test](
	[IBCCustId] [INT] NOT NULL,
	[Username] [NVARCHAR](50) NOT NULL,
	[BetNo] BIGINT NOT NULL,
	[BetAmount] [MONEY] NULL,
	[WinAmount] [MONEY] NULL,
	[Currency] [VARCHAR](5) NULL,
	[ActionTime] [DATETIME] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_Crystal2Test] PRIMARY KEY NONCLUSTERED 
	(
		[BetNo] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_Crystal2Test_WinlostDate] ON [dbo].[bettrans_Crystal2Test]
(
	[WinlostDate] ASC
) ON [ReportData]
GO