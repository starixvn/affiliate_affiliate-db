/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20230828@Sally
	DB: DBAFFN88-Affiliate_N88

	Task: Affiliate - Support VND, BDT, INR currency on Base Currency filter [RedmineID: #193235]
	Step 1:
		- Table ExchangeOanda add column  BDT, INR
*/
-- Run only Affiliate_N88
use Affiliate_N88
GO

UPDATE S SET S.SValue = SValue + ',74:BDT, 61:INR'
FROM dbo.SystemSettings S WITH (UPDLOCK, ROWLOCK)
WHERE SName IN ('AFF_BaseCurrencies')
GO