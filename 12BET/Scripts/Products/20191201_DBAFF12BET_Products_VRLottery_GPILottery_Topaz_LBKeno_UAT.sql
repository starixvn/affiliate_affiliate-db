USE Affiliate_12BET
GO

/*
	Created: 20191201@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products - Insert new products on UAT (istest = 1)
*/

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
SELECT 20, 'GPI Lottery', '12LTGPI', 0, 1, 1
UNION ALL
SELECT 21, 'VR Lottery', '12LTVR', 0, 1, 1
UNION ALL
SELECT 22, 'LB Keno', '12KN', 0, 1, 1
UNION ALL
SELECT 23, '12 Topaz', '12TP', 0, 1, 1