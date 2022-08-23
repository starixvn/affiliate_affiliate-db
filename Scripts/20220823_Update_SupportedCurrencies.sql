/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20220823@Malcolm
	DB: DBAFFN88-Affiliate_N88
	Task: Support currency
*/
UPDATE SystemSettings
	SET SValue = SValue + ',3:USD'
WHERE SName = 'AFF_SupportedCurrencies'

UPDATE SystemSettings
	SET SValue = SValue + ',3:USD'
WHERE SName = 'AFF_PaymentCurrencies'
