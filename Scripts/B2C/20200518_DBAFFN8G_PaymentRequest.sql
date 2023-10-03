/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20200518@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Payment Request - Add more columns
*/

ALTER TABLE dbo.AffPayout
	ADD PreferredPayment		VARCHAR(20)
		,Player_Username		VARCHAR(30)
		,Player_Currency		INT
		,Player_CurrencyName	NVARCHAR(50)
		,Player_CurrencyCode	VARCHAR(3)
GO

UPDATE ap WITH (ROWLOCK)
SET ap.PreferredPayment = ad.PreferredPayment
	,ap.Player_Username = ad.Player_Username
	,ap.Player_Currency = ad.Player_Currency
	,ap.Player_CurrencyName = ad.Player_CurrencyName
	,ap.Player_CurrencyCode = ad.Player_CurrencyCode
FROM dbo.AffPayout ap
	INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ap.AffId = ad.AffId
GO