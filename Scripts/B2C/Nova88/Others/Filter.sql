/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20201215@Percy
	DB:DBAFFN88-Affiliate_N88, DBAFFN8B-Affiliate_N8B, DBAFFN8G-Affiliate_N8G
	Task: Add Payment Currency filter
*/

-- Update Base Currency Id (Code not change)
update Affiliate_N88.dbo.SystemSettings with (rowlock)
set SValue = '2:MYR,3:USD,4:THB,15:IDR,13:CNY'
where SName = 'AFF_BaseCurrencies'

-- Add Payment Currency
insert into Affiliate_N88.dbo.SystemSettings (SName, SValue)
values ('AFF_PaymentCurrencies', '2:MYR,4:THB,15:IDR,13:CNY')

insert into Affiliate_N8B.dbo.SystemSettings (SName, SValue)
values ('AFF_PaymentCurrencies', '51:VND')

insert into Affiliate_N8G.dbo.SystemSettings (SName, SValue)
values ('AFF_PaymentCurrencies', '51:VND')