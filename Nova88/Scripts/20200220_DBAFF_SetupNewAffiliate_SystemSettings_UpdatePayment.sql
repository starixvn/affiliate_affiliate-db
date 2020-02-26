USE Affiliate_N8B
GO

ALTER TABLE dbo.AffDetail
	ADD Player_CurrencyCode VARCHAR(3)
GO
ALTER TABLE dbo.AffInfo
	ADD CurrencyCode VARCHAR(3)
GO

UPDATE ad WITH (ROWLOCK)
SET ad.Player_CurrencyCode = e.Code
FROM dbo.AffDetail ad
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ad.Player_Currency = e.exchangeid
GO
UPDATE ai WITH (ROWLOCK)
SET ai.CurrencyCode = e.Code
FROM dbo.AffInfo ai
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ai.Currency = e.exchangeid
GO
UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = 'Player:Bwing Player Account,Moneybookers:Moneybookers,Wire:Wire Transfer'
WHERE SName = 'Payment_Method'
GO



USE Affiliate_N8G
GO

ALTER TABLE dbo.AffDetail
	ADD Player_CurrencyCode VARCHAR(3)
GO
ALTER TABLE dbo.AffInfo
	ADD CurrencyCode VARCHAR(3)
GO

UPDATE ad WITH (ROWLOCK)
SET ad.Player_CurrencyCode = e.Code
FROM dbo.AffDetail ad
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ad.Player_Currency = e.exchangeid
GO
UPDATE ai WITH (ROWLOCK)
SET ai.CurrencyCode = e.Code
FROM dbo.AffInfo ai
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ai.Currency = e.exchangeid
GO
UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = 'Player:Goal123 Player Account,Moneybookers:Moneybookers,Wire:Wire Transfer'
WHERE SName = 'Payment_Method'
GO