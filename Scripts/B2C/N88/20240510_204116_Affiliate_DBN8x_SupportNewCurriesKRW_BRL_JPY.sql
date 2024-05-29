/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20240513@Sally
	DB: DBN88-bodb_N88
	Task:  Support new currencies KRW, BRL, JPY [RedmineID: #204116]

*/
USE Affiliate_N88
GO
	UPDATE ss SET SValue = '2:MYR,4:THB,15:IDR,13:CNY,61:INR,3:USD,74:BDT,51:VND,45:KRW,32:JPY,82:BRL'
	FROM dbo.SystemSettings ss WITH (UPDLOCK, ROWLOCK)
	WHERE ss.SName in ('AFF_PaymentCurrencies')
GO
	UPDATE ss SET ss.SValue = '2:MYR,4:THB,15:IDR,13:CNY,61:INR,3:USD,74:BDT,51:VND,45:KRW,32:JPY,82:BRL'
	FROM dbo.SystemSettings ss WITH (UPDLOCK, ROWLOCK)
	WHERE ss.SName in ('AFF_SupportedCurrencies')
GO
