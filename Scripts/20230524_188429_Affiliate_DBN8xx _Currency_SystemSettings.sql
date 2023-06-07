/*<info serverAlias="DBAFFN88-Affiliate_N88"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20230522@Sally
	DB: DBN88-bodb_N88
	Task: Affiliate - Handling BDT/ USD (72) currency [RedmineID: #188429]
	Step 2:
		- Config supportCurries, paymentcurrencies for Affiliate_N88
*/
--run only DBAFFN88-Affiliate_N88
USE Affiliate_N88
GO
UPDATE S SET S.SValue = SValue + ',74:BDT'
FROM dbo.SystemSettings S WITH (UPDLOCK, ROWLOCK)
WHERE SName IN ('AFF_PaymentCurrencies','AFF_SupportedCurrencies')
GO
