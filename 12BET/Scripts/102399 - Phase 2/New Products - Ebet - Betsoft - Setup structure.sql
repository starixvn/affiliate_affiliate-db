USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products - Create new tables for import raw data from API
*/

-- raw table Ebet
CREATE TABLE dbo.bettrans_Ebet
(
	betHistoryId	NVARCHAR(100) NOT NULL,
	IBCCustId		INT,
	Username		NVARCHAR(50),
	Bet				MONEY,
	Payout			MONEY,
	PayoutTime		DATETIME,
	WinlostDate		SMALLDATETIME,
	CONSTRAINT [PK_bettrans_Ebet] PRIMARY KEY NONCLUSTERED
	(
		betHistoryId ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_Ebet (WinlostDate) ON [ReportData]
GO

-- raw table Betsoft
CREATE TABLE dbo.bettrans_Betsoft
(
	IBCCustId		INT NOT NULL,
	Username		NVARCHAR(50) NOT NULL,
	GameSessionId	BIGINT NOT NULL,
	GameId			INT NOT NULL,
	PlatForm		VARCHAR(50),
	BetId			INT NOT NULL,
	Amount			MONEY,
	Win				MONEY,
	BetTime			DATETIME,
	WinlostDate		SMALLDATETIME,
	CONSTRAINT [PK_bettrans_Betsoft] PRIMARY KEY NONCLUSTERED
	(
		Username ASC,
		GameSessionId ASC,
		GameId ASC,
		BetId ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_Betsoft (WinlostDate) ON [ReportData]
GO

-- Queue table
CREATE TABLE [dbo].[APIProduct_ImportQueue](
	[QueueId] [int] IDENTITY(1,1) NOT NULL,
	[ProductId] [int] NULL,
	[XmlData] [xml] NULL,
	[JobType] [tinyint] NULL,
	[CheckInTime] [smalldatetime] NULL,
	[FinishedTime] [smalldatetime] NULL,
	[WinlostDate] [smalldatetime] NULL,
	[LogDesc] [varchar](2000) NULL,
 CONSTRAINT [PK_APIProduct_ImportQueue] PRIMARY KEY CLUSTERED 
(
	[QueueId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData] TEXTIMAGE_ON [ReportData]

GO