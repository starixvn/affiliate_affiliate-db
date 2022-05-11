/*<info serverAlias="DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet"></info>*/
/*
	Created: 20220511@Malcolm
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet
	Task: Update product name

*/
UPDATE Product WITH(ROWLOCK)
	SET ProductName = 'Saba Casino', Description = 'Saba Casino'
WHERE ProductName = 'RNG Casino'

UPDATE Product WITH(ROWLOCK)
	SET ProductName = 'RNG Keno'
WHERE ProductName = 'Keno'
