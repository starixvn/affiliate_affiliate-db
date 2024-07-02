/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240702@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Create new table to test data on UAT [RedmineId : #207119]
*/
-- DELETE
DELETE APIProductMappingSettingsTest WITH (ROWLOCK, UPDLOCK) -- 18 rows
GO

DELETE APIProductSettingsTest WITH (ROWLOCK, UPDLOCK) -- 83 rows
WHERE ProductId <> 19 OR ( ProductId = 19 AND SettingName IN ('ExcludeTicketStatus', 'TimeZone'))
GO

DELETE ProductsTest WITH (ROWLOCK, UPDLOCK) -- 39 rows
WHERE ProductId <> 19
GO


-- INSERT
ALTER TABLE [dbo].[APIProduct_TimeTrackerTest]
ADD ProductId INT CONSTRAINT [DF_APIProduct_TimeTrackerTest_ProductId] DEFAULT ((-1))
GO

CREATE NONCLUSTERED INDEX [IX_ProductId_CallTime] ON [dbo].[APIProduct_TimeTrackerTest]
(
	[ProductId] ASC
	,[CallTime] ASC
) ON [ReportData]
GO

ALTER TABLE [dbo].[APIProduct_ImportQueueTest]
ADD ProductId INT CONSTRAINT [DF_APIProduct_ImportQueueTest_ProductId] DEFAULT ((-1)), XmlData XML
GO

CREATE NONCLUSTERED INDEX [IX_ProductId_WinlostDate] ON [dbo].[APIProduct_ImportQueueTest]
(
	[ProductId] ASC
	,[WinlostDate] ASC
) ON [ReportData]
GO

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (45, 'Arcadia Gaming', 'CC', 1, 0, 1, 0, NULL, GETDATE())
      ,(46, 'MaxGame', 'MXG', 1, 0,	1,	0, NULL, GETDATE())
GO



-- UPDATE
DECLARE @Id INT = 0
WHILE 1 = 1
BEGIN
	
	UPDATE [dbo].[APIProduct_TimeTrackerTest] WITH (ROWLOCK, UPDLOCK)
	SET ProductId = -1
	WHERE ProductId IS NULL AND Id >= @Id AND Id < @Id + 5000
	
	IF @@ROWCOUNT = 0
		BREAK

	SET @Id = @Id + 5000
	
	WAITFOR DELAY '00:00:00.280'
END
GO

UPDATE SystemSettingsTest WITH (ROWLOCK, UPDLOCK)
SET SValue = '2024-05-31'
WHERE SName = 'AFF_CommissionDate'
GO

UPDATE APIProductSettingsTest WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '3rdProducts'
WHERE ProductId = 19 AND SettingName = 'SourceTable'
GO


-- New Tables

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


CREATE TABLE [dbo].[bettrans_CrystalTest](
	[operationCode] [BIGINT] NOT NULL,
	[userId] [VARCHAR](50) NULL,
	[changeTime] [DATETIME] NULL,
	[changeType] [VARCHAR](20) NULL,
	[gameName] [VARCHAR](200) NULL,
	[fround] [SMALLINT] NULL,
	[bet] [MONEY] NULL,
	[ret] [MONEY] NULL,
	[changes] [MONEY] NULL,
	[endBalance] [MONEY] NULL,
	[operator] [VARCHAR](50) NULL,
	[jcon] [MONEY] NULL,
	[jwin] [MONEY] NULL,
	[platform] [TINYINT] NULL,
	[gametype] [SMALLINT] NULL,
	[ver] [VARCHAR](20) NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_CrystalTest] PRIMARY KEY NONCLUSTERED 
	(
		[operationCode] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_CrystalTest_WinlostDate] ON [dbo].[bettrans_CrystalTest]
(
	[WinlostDate] ASC
) ON [ReportData]
GO


CREATE TABLE [dbo].[bettrans_Topaz2Test](
	[id] [BIGINT] NOT NULL,
	[wager] [MONEY] NULL,
	[payout] [MONEY] NULL,
	[revenue] [MONEY] NULL,
	[account_id] [BIGINT] NULL,
	[account_ext_ref] [VARCHAR](50) NULL,
	[currency_unit] [VARCHAR](5) NULL,
	[transaction_time] [DATETIME] NULL,
	[created] [DATETIME] NULL,
	[category] [VARCHAR](50) NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	[betcount] [INT] NULL,
	CONSTRAINT [PK_bettrans_Topaz2Test] PRIMARY KEY NONCLUSTERED 
	(
		[id] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_Topaz2Test_WinlostDate] ON [dbo].[bettrans_Topaz2Test]
(
	[WinlostDate] ASC
) ON [ReportData]
GO


CREATE TABLE [dbo].[bettrans_BTiTest](
	[BetID] [BIGINT] NOT NULL,
	[UserName] [VARCHAR](50) NULL,
	[TotalStake] [MONEY] NULL,
	[ValidStake] [MONEY] NULL,
	[PL] [MONEY] NULL,
	[BetStatus] [VARCHAR](30) NULL,
	[BetSettledDate] [DATETIME] NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_BTiTest] PRIMARY KEY NONCLUSTERED 
	(
		[BetID] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_BTiTest_WinlostDate] ON [dbo].[bettrans_BTiTest]
(
	[WinlostDate] ASC
) ON [ReportData]
GO


CREATE TABLE [dbo].[bettrans_BTi2Test](
	[PurchaseId] [BIGINT] NOT NULL,
	[UserName] [VARCHAR](50) NULL,
	[TotalStake] [MONEY] NULL,
	[ValidStake] [MONEY] NULL,
	[PL] [MONEY] NULL,
	[BetStatus] [VARCHAR](30) NULL,
	[BetSettledDate] [DATETIME] NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_BTi2Test] PRIMARY KEY NONCLUSTERED 
	(
		[PurchaseId] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_BTi2Test_WinlostDate] ON [dbo].[bettrans_BTi2Test]
(
	[WinlostDate] ASC
) ON [ReportData]
GO


CREATE TABLE [dbo].[bettrans_N2Test](
	[dealId] [BIGINT] NULL,
	[startdate] [DATETIME] NULL,
	[enddate] [DATETIME] NULL,
	[status] [TINYINT] NULL,
	[code] [VARCHAR](100) NULL,
	[login] [VARCHAR](50) NULL,
	[valid_turnover] [MONEY] NULL,
	[hold] [MONEY] NULL,
	[betid] [BIGINT] NOT NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_N2Test] PRIMARY KEY NONCLUSTERED 
	(
		[betid] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_N2Test_WinlostDate] ON [dbo].[bettrans_N2Test]
(
	[WinlostDate] ASC
) ON [ReportData]
GO

CREATE TABLE [dbo].[bettrans_EATest](
	[dealId] [BIGINT] NULL,
	[startdate] [DATETIME] NULL,
	[enddate] [DATETIME] NULL,
	[status] [TINYINT] NULL,
	[code] [VARCHAR](100) NULL,
	[login] [VARCHAR](50) NULL,
	[valid_turnover] [MONEY] NULL,
	[hold] [MONEY] NULL,
	[betid] [BIGINT] NOT NULL,
	[IBCCustId] [INT] NULL,
	[WinlostDate] [SMALLDATETIME] NULL,
	CONSTRAINT [PK_bettrans_EATest] PRIMARY KEY NONCLUSTERED 
	(
		[betid] ASC
	) ON [ReportData]
) ON [ReportData]
GO
CREATE CLUSTERED INDEX [CIX_EATest_WinlostDate] ON [dbo].[bettrans_EATest]
(
	[WinlostDate] ASC
) ON [ReportData]
GO