/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240730@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for BetSoft on UAT [RedmineId : #207119]
*/

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (11, '12Amber - Betsoft', '12BS', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (11, 'LastQueueId', '0')
	 , (11, 'LaunchDate', '2018-12-01')
	 , (11, 'SourceTable', 'APIProduct_ImportQueueTest')
GO

-- Drop table 
DROP TABLE bettrans_BetsoftTest
GO
DROP TABLE bettrans_BTiTest
GO

-- New table
CREATE TABLE [dbo].[bettrans_Betsoft2Test](
	[IBCCustId] [INT] NOT NULL,
	[Username] [NVARCHAR](50) NOT NULL,
	[BetOrderNo] [VARCHAR](50) NOT NULL,
	[ValidBetAmount] [MONEY] NULL,
	[Payout] [MONEY] NULL,
	[Currency] [VARCHAR](5) NULL,
	[BetTime] [DATETIME] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_Betsoft2Test] PRIMARY KEY NONCLUSTERED 
	(
		[BetOrderNo] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_Betsoft2Test_WinlostDate] ON [dbo].[bettrans_Betsoft2Test]
(
	[WinlostDate] ASC
) ON [ReportData]
GO