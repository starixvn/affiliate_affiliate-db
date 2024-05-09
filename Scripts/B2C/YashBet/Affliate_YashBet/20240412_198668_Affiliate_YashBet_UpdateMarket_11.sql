/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Support new Aff Yashbet
		2. Update data 
*/


DELETE m
FROM Market m (ROWLOCK)
WHERE m.MarketId ='bn-BD'