USE Affiliate_N8B
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('Payment_MinAmount', '2300')
		,('Payment_Method', 'Bwing Player Account,Moneybookers,Wire Transfer')
		,('BrandName', 'Bwing')
GO

USE Affiliate_N8G
GO

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('Payment_MinAmount', '2300')
		,('Payment_Method', 'Goal123 Player Account,Moneybookers,Wire Transfer')
		,('BrandName', 'Goal123')
GO