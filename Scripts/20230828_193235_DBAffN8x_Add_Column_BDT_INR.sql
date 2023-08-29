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
  use Affiliate_N88
 -- use Affiliate_N8B
 -- use Affiliate_N8G
GO

-- 1. Add column BDT, INR table ExchangeOanda
	ALTER TABLE dbo.ExchangeOanda
	ADD BDT FLOAT NULL,
		INR FLOAT NULL

GO

-- 2.Migrate data column BDT, INR
	DECLARE @Source_MaxExchangeDate DATE
		,@Target_MaxExchangeDate DATE

	SELECT @Source_MaxExchangeDate = MAX(edo.ExchangeDate)
	FROM bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK)
	
	SELECT @Target_MaxExchangeDate = MAX(edo.ExchangeDate)
	FROM dbo.ExchangeOanda edo WITH (NOLOCK)

	-- ~ 4k4 rows
	UPDATE e 
	SET e.BDT = edo.BDT
	   ,e.INR = edo.INR
	FROM dbo.ExchangeOanda e WITH (ROWLOCK) 
		INNER JOIN bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK)
		ON e.ExchangeId = edo.ExchangeId
		AND e.ExchangeDate = edo.ExchangeDate

	-- Case ExchangeDate of ExchangeOanda is greater than bodb02.dbo.ExchangeDailyOanda
	IF(DATEDIFF(DAY, @Target_MaxExchangeDate, @Source_MaxExchangeDate) <0)
	BEGIN
		-- <200 rows
		;WITH CTE_ExchangeOanda AS (
			SELECT e.ExchangeId
				,e.ExchangeDate
				,e.BDT
				,e.INR
			FROM dbo.ExchangeOanda e WITH (ROWLOCK)
			WHERE e.ExchangeDate >@Source_MaxExchangeDate
		)
		UPDATE e 
		SET e.BDT = f.BDT
		   ,e.INR = f.INR
		FROM CTE_ExchangeOanda e
			INNER JOIN ( 
				SELECT edo.ExchangeDate
					,edo.ExchangeId
					,edo.BDT
					,edo.INR  
				FROM bodb02.dbo.ExchangeDailyOanda edo WITH (NOLOCK)
				WHERE edo.ExchangeDate = @Source_MaxExchangeDate
			)f ON e.ExchangeDate = EOMONTH(f.ExchangeDate)
				AND e.ExchangeId = f.ExchangeId

	END
