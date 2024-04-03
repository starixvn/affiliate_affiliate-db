/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20231109@Sally
	DB: DBAFFN88-Affiliate_N88
	Task:N88 Aff - Some SPs are retrieving incorrect Player_CurrencyName and Player_CurrencyCode values [RedmineID: #196628]
		- Update correctly the data Player_currencyName,  Player_currencyCode 		

*/  
	USE Affiliate_N88
	GO

	DECLARE @C1 BIGINT = 0, @C2 BIGINT = 0, @C3 BIGINT = 0

	SELECT @C1 = COUNT(1) --  0 row
	FROM dbo.TransferBalanceHistory WITH (NOLOCK)
	WHERE (Player_Currency = 74 AND Player_CurrencyCode <> 'BDT')
		OR
		(Player_Currency = 72 AND Player_CurrencyCode <> 'USD')
	;
	SELECT @C2 = COUNT(1) -- 1 row
	FROM dbo.AffPayout WITH (NOLOCK)
	WHERE (Player_Currency = 74 AND Player_CurrencyCode <> 'BDT')
		OR
		(Player_Currency = 72 AND Player_CurrencyCode <> 'USD')

	SELECT @C3 = COUNT(1) -- 131 rows
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE (Player_Currency = 74 AND Player_CurrencyCode <> 'BDT')
		OR
		(Player_Currency = 72 AND Player_CurrencyCode <> 'USD')

	-- SELECT @C1 AS TransferBalanceHistory, @C2 AS AffPayout, @C3 AS AffDetail

	--1. Table TransferBalanceHistory
	IF (@C1 <> 0)
	BEGIN
		UPDATE t SET t.Player_CurrencyCode = 'BDT'
		FROM dbo.TransferBalanceHistory t WITH (UPDLOCK)
		WHERE Player_Currency = 74  AND Player_CurrencyCode <> 'BDT'

		UPDATE t SET t.Player_CurrencyCode = 'USD'
		FROM dbo.TransferBalanceHistory t WITH (UPDLOCK)
		WHERE Player_Currency = 72  AND Player_CurrencyCode <> 'USD'
	END

	--2. Table AffPayout
	IF (@C2 <> 0)
	BEGIN
		UPDATE t SET t.Player_CurrencyCode = 'BDT', t.Player_CurrencyName = 'BDT'
		FROM dbo.AffPayout t WITH (UPDLOCK)
		WHERE Player_Currency = 74 AND Player_CurrencyCode <> 'BDT'

		UPDATE t SET t.Player_CurrencyCode = 'USD', t.Player_CurrencyName = 'US$'
		FROM dbo.AffPayout t WITH (UPDLOCK)
		WHERE Player_Currency = 72 AND Player_CurrencyCode <> 'USD'
	END

	--3. Table AffDetail
	IF (@C3 <> 0)
	BEGIN
		UPDATE t SET t.Player_CurrencyCode = 'BDT', t.Player_CurrencyName = 'BDT'
		FROM dbo.AffDetail t WITH (UPDLOCK)
		WHERE Player_Currency = 74 AND Player_CurrencyCode <> 'BDT'

		UPDATE t SET t.Player_CurrencyCode = 'USD', t.Player_CurrencyName = 'US$'
		FROM dbo.AffDetail t WITH (UPDLOCK)
		WHERE Player_Currency = 72 AND Player_CurrencyCode <> 'USD'
	END

