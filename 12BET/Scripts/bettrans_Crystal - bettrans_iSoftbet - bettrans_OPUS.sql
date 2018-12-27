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

CREATE TABLE [dbo].[bettrans_OPUS]
(
	transaction_id			BIGINT NOT NULL,
    transaction_date_time	DATETIME,
    member_code				VARCHAR(30),
    member_type				VARCHAR(10),
    currency				VARCHAR(5),
    balance_start			MONEY,
    balance_end				MONEY,
    bet						MONEY,
    win						MONEY,
    game_code				VARCHAR(5),
    game_detail				VARCHAR(300),
    bet_status				VARCHAR(10),
    player_hand				NVARCHAR(4000),
    game_result				VARCHAR(500),
    game_category			VARCHAR(10),
    vendor					VARCHAR(20),
    DrawNumber				INT,
    m88_studio				VARCHAR(5),
    stamp_date				DATETIME,
    bet_record_id			VARCHAR(10),
	IBCCustId				INT,
	WinlostDate				SMALLDATETIME
	CONSTRAINT [PK_bettrans_OPUS] PRIMARY KEY NONCLUSTERED 
	(
		transaction_id ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [ReportData]
) ON [ReportData]
GO

CREATE CLUSTERED INDEX [CIX_WinlostDate] ON [dbo].[bettrans_OPUS] (WinlostDate)
GO
