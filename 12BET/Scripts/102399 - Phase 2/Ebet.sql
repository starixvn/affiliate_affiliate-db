USE [Affiliate_12BET]
GO

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