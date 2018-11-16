USE [Affiliate_12BET]
GO

/*
	Created: 20181101@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Rename market name

	SELECT TOP (12) *
	FROM dbo.Market WITH (NOLOCK)
*/

UPDATE dbo.Market WITH (ROWLOCK, UPDLOCK)
SET MarketName = CASE MarketName
					WHEN 'English_Euro' THEN 'English (Europe)'
					WHEN 'Espanol' THEN 'Spanish'
					WHEN 'Republic of India' THEN 'English (India)'
					WHEN 'Indonesia' THEN 'Indonesian'
					WHEN 'Vietnam' THEN 'Vietnamese'
					ELSE MarketName END