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