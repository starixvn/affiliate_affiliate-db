/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20230828@Sally
	DB: 
		- DBAFFN88-Affiliate_N88
		- DBAFFN8B-Affiliate_N8B
		- DBAFFN8G-Affiliate_N8G
	Task: Affiliate - Support VND, BDT, INR currency on Base Currency filter [RedmineID: #193235]
	Step 1:
		- Table ExchangeOanda add column  BDT, INR
		- Migrate data column BDT, INR
*/
 -- use Affiliate_N88
 -- use Affiliate_N8B
 -- use Affiliate_N8G
GO

-- 1. Add column BDT, INR table ExchangeOanda
	ALTER TABLE dbo.ExchangeOanda
	ADD BDT FLOAT NULL,
		INR FLOAT NULL

GO

-- 2.Migrate data column BDT, INR
-- ~ 4k3 rows
	UPDATE e WITH (ROWLOCK)
	SET e.BDT = edo.BDT
	   ,e.INR = edo.INR
	FROM dbo.ExchangeOanda e
	INNER JOIN bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK)
		ON e.ExchangeId = edo.ExchangeId
		AND e.ExchangeDate = edo.ExchangeDate
	;