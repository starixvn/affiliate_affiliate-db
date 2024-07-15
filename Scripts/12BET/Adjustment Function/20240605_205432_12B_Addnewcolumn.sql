/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240605@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column [RedmineId : #205432]
*/
-- Customer >> Adjustment >> Description ('Visible only to admin' & 'Visible also to affiliate')

ALTER TABLE AffTrans
ADD AffDescription NVARCHAR(300)
GO