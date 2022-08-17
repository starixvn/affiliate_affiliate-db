/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220810@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

UPDATE Market WITH(ROWLOCK)
SET ShortedCode = 'kh'
WHERE MarketName = 'Cambodian'