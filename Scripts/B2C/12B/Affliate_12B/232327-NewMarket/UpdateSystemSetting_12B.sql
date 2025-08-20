/*<info serverAlias="DBAFF12B-Affiliate_12B"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20250616@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Support PHP [RedmineID: #228787]

*/
USE Affiliate_12B
GO

UPDATE S SET S.SValue = SValue + ',42:PHP'
FROM dbo.SystemSettings S WITH (UPDLOCK, ROWLOCK)
WHERE SName IN ('AFF_PaymentCurrencies','AFF_SupportedCurrencies')
GO
