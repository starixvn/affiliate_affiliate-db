/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

CREATE TABLE dbo.APIProductMappingSettings
(
	TpType		INT
	,SubItem	VARCHAR(200)
	,ProductId	INT
	,CONSTRAINT [PK_APIProductMappingSettings] PRIMARY KEY CLUSTERED
	(
		TpType ASC
		,SubItem ASC
	)
) ON [SettingData]
GO

CREATE NONCLUSTERED INDEX IX_ProductId ON APIProductMappingSettings (ProductId)
GO

INSERT INTO dbo.APIProductMappingSettings(TpType, SubItem, ProductId)
VALUES (1, '', 3), (9, '', 10) 

GO

CREATE TABLE dbo.bettrans_APIProducts
(
	TpType					INT
	,SubItem				VARCHAR(200)
	,Bet					MONEY
	,BetStatus				VARCHAR(10)
	,GamePlatform			VARCHAR(20)
	,IsHedgebet				BIT
	,ThirdPartyId			INT
	,TransactionbDatetime	DATETIME
	,TransactionId			VARCHAR(50)
	,Username				VARCHAR(50)
	,ValidBet				MONEY
	,Win					MONEY
	,IBCCustId				INT
	,WinlostDate			SMALLDATETIME
	,CONSTRAINT [PK_bettrans_APIProducts] PRIMARY KEY NONCLUSTERED 
	(
		TpType ASC
		,SubItem ASC
		,TransactionId ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate_TpType_SubItem_IBCCustId ON bettrans_APIProducts (WinlostDate, TpType, SubItem, IBCCustId)
GO

CREATE TABLE dbo.bettrans_APIProducts_bk
(
	TpType					INT
	,SubItem				VARCHAR(200)
	,Bet					MONEY
	,BetStatus				VARCHAR(10)
	,GamePlatform			VARCHAR(20)
	,IsHedgebet				BIT
	,ThirdPartyId			INT
	,TransactionbDatetime	DATETIME
	,TransactionId			VARCHAR(50)
	,Username				VARCHAR(50)
	,ValidBet				MONEY
	,Win					MONEY
	,IBCCustId				INT
	,WinlostDate			SMALLDATETIME
	,CONSTRAINT [PK_bettrans_APIProducts_bk] PRIMARY KEY NONCLUSTERED 
	(
		TpType ASC
		,SubItem ASC
		,TransactionId ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_WinlostDate_TpType_SubItem_IBCCustId ON bettrans_APIProducts_bk (WinlostDate, TpType, SubItem, IBCCustId)
GO




