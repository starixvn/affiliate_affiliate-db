/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support new Aff Yashbet
		2. Update  base Currency UUS
*/
USE Affiliate_YashBet
GO
UPDATE c SET SValue = '61:INR,74:BDT,3:USD,20:UUS'
FROM dbo.SystemSettings c WITH (UPDLOCK)
WHERE c.SName IN ('AFF_BaseCurrencies')
