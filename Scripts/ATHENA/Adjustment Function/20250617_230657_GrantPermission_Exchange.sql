/*<info serverAlias="DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet"></info>*/
/*
	Created: 20250617@Sophia
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo,DBAFF-Affiliate_9Bet
	Task: add permisison for wsv_afinet to view Exchange table [redmine: #230657]
*/

GRANT SELECT ON [Exchange] TO [wsv_afinet];
GRANT UPDATE ON [Exchange] TO [wsv_afinet];
GRANT SELECT ON [ExchangeDaily] TO [wsv_afinet];
GRANT UPDATE ON [ExchangeDaily] TO [wsv_afinet];