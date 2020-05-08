USE Affiliate_N8G
GO

/*
	Created: 20200507@Percy
	DB: DBAFFN8G.Affiliate_N8G
	Task: Integrate 8 products
*/

INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, Enabled, IsTest, ReleasedDate, RefProductId, DataSource)
VALUES
	(12, 'Allbet L.Casino', 'ABLC', 0, 1, 0, '2020-01-01', 6, 'TpBetRecord')
	,(13, 'PP RNG', 'PPRNG', 0, 1, 0, '2020-01-01', 7, 'TpBetRecord')
	,(14, 'GPI RNG', 'GPIRNG', 0, 1, 0, '2020-01-01', 11, 'TpBetRecord')
	,(15, 'YL Fishing', 'YL', 0, 1, 0, '2020-01-01', 12, 'TpBetRecord')
	,(16, 'Joker RNG', 'JRNG', 0, 1, 0, '2020-01-01', 13, 'TpBetRecord')
	,(17, 'YGG RNG', 'YGGRNG', 0, 1, 0, '2020-01-01', 14, 'TpBetRecord')
	,(18, 'SG RNG', 'SGRNG', 0, 1, 0, '2020-01-01', 15, 'TpBetRecord')
	,(19, 'PP L.Casino', 'PPLC', 0, 1, 0, '2020-01-01', 16, 'TpBetRecord')