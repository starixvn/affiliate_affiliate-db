USE [Affiliate_12BET]
GO

/*
	Created: 20180910@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products [RedmineID: #87923]
*/

DELETE dbo.Products WITH (ROWLOCK, UPDLOCK)
WHERE ProductId < 0
GO

INSERT INTO dbo.Products (ProductId, ProductName, ProductPrefix, IsIBC, TransferType, Enabled, IsTest)
VALUES
	(4, 'Number Game', 'NG', 1, 0, 1, 0),
	(5, 'Virtual Sports', 'VS', 1, 0, 1, 0),
	(6, 'Keno', 'KN', 1, 0, 1, 0),
	(7, 'Virtual Sports 2', 'VS2', 1, 0, 1, 0),
	(8, 'Lottery', 'LT', 1, 0, 1, 0)
GO