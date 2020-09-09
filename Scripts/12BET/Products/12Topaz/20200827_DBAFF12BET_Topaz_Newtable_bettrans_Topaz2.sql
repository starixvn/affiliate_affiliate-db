/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20200827@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Re-integrate 12Topaz product - create neew table bettrans_Topaz2
*/

USE Affiliate_12BET
GO

CREATE TABLE dbo.bettrans_Topaz2 (
	id					BIGINT NOT NULL
	,betcount			INT
	,wager				MONEY
	,payout				MONEY
	,revenue			MONEY
	,account_id			BIGINT
	,account_ext_ref	VARCHAR(50)
	,currency_unit		VARCHAR(5)
	,transaction_time	DATETIME
	,created			DATETIME
	,category			VARCHAR(50)
	,IBCCustId			INT
	,WinlostDate		SMALLDATETIME
	,CONSTRAINT PK_bettrans_Topaz2 PRIMARY KEY NONCLUSTERED
	(
		id ASC
	) ON ReportData
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_bettrans_Topaz2 ON dbo.bettrans_Topaz2 (WinlostDate) ON ReportData
GO