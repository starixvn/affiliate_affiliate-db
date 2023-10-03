/*<info serverAlias="DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet"></info>*/
/*
	Created: 20220601@Malcolm
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet
	Task: Update IsEnabled = 0

*/

UPDATE product WITH(ROWLOCK)
	SET IsEnabled = 0
WHERE ProductName IN ('Live Casino', 'Gold Deluxe', 'Macau', 'Racing') 