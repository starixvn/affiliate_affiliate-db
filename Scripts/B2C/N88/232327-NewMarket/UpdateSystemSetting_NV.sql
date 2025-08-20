/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20250616@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Support PHP [RedmineID: #228787]

*/
UPDATE S SET S.SValue = SValue + ',42:PHP'
FROM dbo.SystemSettings S WITH (UPDLOCK, ROWLOCK)
WHERE SName IN ('AFF_PaymentCurrencies','AFF_SupportedCurrencies')
GO