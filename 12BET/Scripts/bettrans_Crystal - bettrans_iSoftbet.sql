USE [Affiliate_12BET]
GO

CREATE TABLE [dbo].[bettrans_Crystal]
(
	operationCode	BIGINT NOT NULL,
	userId			VARCHAR(50),
	changeTime		DATETIME,
	changeType		VARCHAR(20),
	gameName		VARCHAR(200),
	fround			SMALLINT,
	bet				MONEY,
	ret				MONEY,
	changes			MONEY,
	endBalance		MONEY,
	operator		VARCHAR(50),
	jcon			MONEY,
	jwin			MONEY,
	platform		TINYINT,
	gametype		SMALLINT,
	ver				VARCHAR(20),
	IBCCustId		INT,
	WinlostDate		SMALLDATETIME
	CONSTRAINT [PK_bettrans_Crystal] PRIMARY KEY NONCLUSTERED 
	(
		operationCode ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX [CIX_WinlostDate] ON [dbo].[bettrans_Crystal] (WinlostDate)
GO

CREATE TABLE [dbo].[bettrans_iSoftbet]
(
	PLAYERID		VARCHAR(50),
	CURRENCY		VARCHAR(5),
	SESSIONID		VARCHAR(100),
	GAMEID			VARCHAR(10),
	ROUNDID			VARCHAR(100),
	TRANSACTIONID	VARCHAR(100) NOT NULL,
	TYPE			VARCHAR(50),
	TIME			DATETIME,
	AMOUNT			MONEY,
	IBCCustId		INT,
	WinlostDate		SMALLDATETIME
	CONSTRAINT [PK_bettrans_iSoftbet] PRIMARY KEY NONCLUSTERED 
	(
		TRANSACTIONID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX [CIX_WinlostDate] ON [dbo].[bettrans_iSoftbet] (WinlostDate)
GO