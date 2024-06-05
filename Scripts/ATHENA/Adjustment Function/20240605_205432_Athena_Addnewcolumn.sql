/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20240606@Eddie
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: Add new column [RedmineId : #205432]
*/
-- Affiliate Info >> Adjustment >> Description ('Visible only to admin' & 'Visible also to affiliate')

ALTER TABLE AffTrans
ADD AffDescription NVARCHAR(300)
GO