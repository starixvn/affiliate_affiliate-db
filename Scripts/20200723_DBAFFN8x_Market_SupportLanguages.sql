/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Add column IDR, THB on Exchange/ExchangeOanda for Base currency on Client
*/

/*
USE Affiliate_N8B
USE Affiliate_N8G
*/

DELETE dbo.Market WITH (ROWLOCK, UPDLOCK)
WHERE MarketId NOT IN ('en-US', 'vi-VN')
GO