/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Add column IDR, THB on Exchange/ExchangeOanda for Base currency on Client
*/

/*
USE Affiliate_N88
GO
USE Affiliate_N8B
GO
USE Affiliate_N8G
GO
*/

ALTER TABLE dbo.Exchange
	ADD THB FLOAT
		,IDR FLOAT
GO
ALTER TABLE dbo.ExchangeOanda
	ADD THB FLOAT
		,IDR FLOAT
GO
UPDATE e WITH (ROWLOCK)
SET e.THB = edo.THB, e.IDR = edo.IDR
FROM dbo.Exchange e
	INNER JOIN bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK) ON e.ExchangeId = edo.ExchangeId
WHERE edo.ExchangeDate = '2020-06-28' -- current yesterday
GO
UPDATE e WITH (ROWLOCK)
SET e.THB = edo.THB, e.IDR = edo.IDR
FROM dbo.ExchangeOanda e
	INNER JOIN bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK)
		ON e.ExchangeId = edo.ExchangeId AND e.ExchangeDate = edo.ExchangeDate
GO