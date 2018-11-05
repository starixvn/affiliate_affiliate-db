USE [Affiliate_12BET]
GO

CREATE TABLE dbo.bettrans_Betsoft
(
	IBCCustId		INT,
	Username		NVARCHAR(50),
	GameSessionId	BIGINT,
	GameId			INT,
	PlatForm		VARCHAR(50),
	BetId			INT,
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