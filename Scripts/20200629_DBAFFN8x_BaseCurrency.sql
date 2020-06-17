/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20200605@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G

	Task: Add default base currency, approved by on client site
*/

USE Affiliate_N88
GO

ALTER TABLE dbo.AffInfo
	ADD ApprovedBy INT
		,DefaultCurrency INT
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET ApprovedBy = 1000000004 -- AAStarixQC
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET DefaultCurrency = Currency
GO
UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = '2:MYR,3:USD,43:THB,34:IDR,13:CNY'
WHERE SName = 'AFF_BaseCurrencies'
GO


-------------
USE Affiliate_N8B
GO

ALTER TABLE dbo.AffInfo
	ADD ApprovedBy INT
		,DefaultCurrency INT
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET ApprovedBy = 1000000004 -- AAStarixQC
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET DefaultCurrency = Currency
GO
UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = '51:VND,3:USD'
WHERE SName = 'AFF_BaseCurrencies'
GO



-------------
USE Affiliate_N8G
GO

ALTER TABLE dbo.AffInfo
	ADD ApprovedBy INT
		,DefaultCurrency INT
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET ApprovedBy = 1000000004 -- AAStarixQC
GO
UPDATE dbo.AffInfo WITH (ROWLOCK)
SET DefaultCurrency = Currency
GO
UPDATE dbo.SystemSettings WITH (ROWLOCK)
SET SValue = '51:VND,3:USD'
WHERE SName = 'AFF_BaseCurrencies'
GO