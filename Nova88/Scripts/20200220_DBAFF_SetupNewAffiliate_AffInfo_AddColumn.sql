USE Affiliate_N8B
GO

ALTER TABLE dbo.AffInfo
	ADD CurrencyName NVARCHAR(50)

ALTER TABLE dbo.AffDetail
	ADD Player_CurrencyName NVARCHAR(50)
GO


------------
USE Affiliate_N8G
GO

ALTER TABLE dbo.AffInfo
	ADD CurrencyName NVARCHAR(50)

ALTER TABLE dbo.AffDetail
	ADD Player_CurrencyName NVARCHAR(50)
GO