/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200518@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Payment Request - Add more columns
*/

ALTER TABLE dbo.AffPayout
	ADD PreferredPayment		VARCHAR(20)
		,Player_Username		VARCHAR(30)
		,Player_Currency		INT
		,Player_CurrencyName	NVARCHAR(50)
		,Player_CurrencyCode	VARCHAR(3)
GO

-- add JPY currency for N88 (payment)
INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('AFF_BalPlayerJPY', 'N88AFFPlayerJPY')
GO