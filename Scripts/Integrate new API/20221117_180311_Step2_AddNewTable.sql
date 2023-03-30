/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/
CREATE NONCLUSTERED INDEX IX_ProductId ON APIProductMappingSettings (ProductId)
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






