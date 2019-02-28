USE [Affiliate_12BET]
GO

/*
	Created: 20190228@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new 4 products
*/

DECLARE @ReleasedDate SMALLDATETIME = '2019-03-01'

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate)
SELECT 15, 'Allbet', 'AB', 1, 1, 0, @ReleasedDate UNION ALL
SELECT 16, 'RNG Casino', 'CS', 1, 1, 0, @ReleasedDate UNION ALL
SELECT 17, 'Gold Deluxe', 'GD', 0, 1, 0, @ReleasedDate UNION ALL
SELECT 18, 'Macau Games', 'VB', 1, 1, 0, @ReleasedDate