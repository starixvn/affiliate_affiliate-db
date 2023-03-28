/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230324@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Update value and show Bangladesh language [RedmineId : #185446]
*/
UPDATE dbo.SystemSettings
SET SValue = 'TB;US$;EURO;GBP;RM;RMB;AUD;CHF;SD$;IN;UUS;VND;WON;JPY;INR;MKK;KHR;BDT'
WHERE SName = 'AFF_SupportedCurrencies'
GO