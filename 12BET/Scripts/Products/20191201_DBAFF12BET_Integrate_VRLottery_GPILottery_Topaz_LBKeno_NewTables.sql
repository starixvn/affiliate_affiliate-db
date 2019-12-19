USE Affiliate_12BET
GO

/*
	Created: 20191201@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products - Add new tables
*/

CREATE TABLE dbo.bettrans_Topaz
(
	id bigint NOT NULL,
	partyId int NULL,
	userId varchar(50) NULL,
	gameInfoId int NULL,
	gameTranId varchar(100) NULL,
	platformCode varchar(20) NULL,
	platformTranId varchar(50) NULL,
	gameId varchar(20) NULL,
	tranType varchar(20) NULL,
	dateTime datetime NULL,
	amount money NULL,
	currency varchar(3) NULL,
	balance money NULL,
	rollbackTranId bigint NULL,
	rollbackTranType varchar(20) NULL,
	IBCCustId int NULL,
	WinlostDate smalldatetime NULL,
	CONSTRAINT PK_bettrans_Topaz PRIMARY KEY NONCLUSTERED 
	(
		id ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON ReportData
) ON ReportData
GO

CREATE TABLE dbo.bettrans_GPILottery
(
	memberId varchar(50) NULL,
	memberType varchar(10) NULL,
	betId bigint NOT NULL,
	betNo varchar(50) NULL,
	drawId bigint NULL,
	drawNo varchar(50) NULL,
	areaName varchar(50) NULL,
	isRNG bit NULL,
	betType varchar(50) NULL,
	betContent varchar(20) NULL,
	currency varchar(10) NULL,
	betAmount money NULL,
	odds float NULL,
	isWin bit NULL,
	winAmount money NULL,
	timeBet datetime NULL,
	actionTime datetime NULL,
	status varchar(20) NULL,
	OS varchar(10) NULL,
	IBCCustId int NULL,
	WinlostDate smalldatetime NULL,
	CONSTRAINT PK_bettrans_GPILottery PRIMARY KEY NONCLUSTERED 
	(
		betId ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON ReportData
) ON ReportData
GO

CREATE TABLE dbo.bettrans_VRLottery
(
	Provider varchar(20) NULL,
	GameId varchar(30) NULL,
	GameName varchar(100) NULL,
	GameNo varchar(20) NULL,
	GameNoId int NULL,
	PlayerId varchar(50) NULL,
	ProviderPlayerId nvarchar(200) NULL,
	Currency varchar(10) NULL,
	Tray smallint NULL,
	BetId varchar(50) NOT NULL,
	BetOn nvarchar(50) NULL,
	BetType nvarchar(100) NULL,
	BetDetails varchar(100) NULL,
	Odds money NULL,
	BetAmount money NULL,
	ValidBet money NULL,
	WinLoss money NULL,
	PlayerWinLoss money NULL,
	LossPrize money NULL,
	Tips money NULL,
	CommissionRate float NULL,
	Commission money NULL,
	Status varchar(20) NULL,
	Platform varchar(20) NULL,
	BetDate datetime NULL,
	ResultDate datetime NULL,
	DateCreated datetime NULL,
	LastUpdatedDate datetime NULL,
	IBCCustId int NULL,
	WinlostDate smalldatetime NULL,
	CONSTRAINT PK_bettrans_VRLottery PRIMARY KEY NONCLUSTERED 
	(
		BetId ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON ReportData
) ON ReportData
GO

CREATE TABLE dbo.bettrans_LBKeno
(
	member_id varchar(50) NULL,
	member_type varchar(10) NULL,
	session_token varchar(200) NULL,
	bet_id bigint NOT NULL,
	bet_no varchar(50) NULL,
	match_no varchar(10) NULL,
	match_area varchar(10) NULL,
	match_id int NULL,
	bet_type varchar(10) NULL,
	bet_content nvarchar(50) NULL,
	bet_currency varchar(5) NULL,
	bet_money money NULL,
	bet_odds float NULL,
	bet_winning money NULL,
	bet_win varchar(20) NULL,
	bet_status varchar(20) NULL,
	bet_time datetime NULL,
	trans_time datetime NULL,
	bet_platform varchar(20) NULL,
	bet_previous_id bigint NULL,
	IBCCustId int NULL,
	WinlostDate smalldatetime NULL,
	CONSTRAINT PK_bettrans_LBKeno PRIMARY KEY NONCLUSTERED 
	(
		bet_id ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON ReportData
) ON ReportData
GO

-- indexes
CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_Topaz (WinlostDate ASC) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_GPILottery (WinlostDate ASC) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_VRLottery (WinlostDate ASC) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate ON dbo.bettrans_LBKeno (WinlostDate ASC) ON ReportData
GO