/*<info serverAlias="DBAFFN88-Affiliate_N88"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20230720@Sally
	DB: DBN88-bodb_N88
	Task: N88 Aff - Support INH [RedmineID: #191307]
		- Config supportCurries, paymentcurrencies AFF_BaseCurrencies INH for Affiliate_N88
*/
--run only DBAFFN88-Affiliate_N88
USE Affiliate_N88
GO
UPDATE S SET S.SValue = SValue + ',51:VND'
FROM dbo.SystemSettings S WITH (UPDLOCK, ROWLOCK)
WHERE SName IN ('AFF_PaymentCurrencies','AFF_SupportedCurrencies')
GO

SELECT *
FROM dbo.SystemSettings S WITH (NOLOCK)
WHERE SName IN ('AFF_PaymentCurrencies','AFF_SupportedCurrencies')
;
