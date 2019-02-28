USE [Affiliate_12BET]
GO

/*
	Created: 20190228@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new column for Product's released date
*/

ALTER TABLE dbo.Products
	ADD ReleasedDate SMALLDATETIME NULL
GO

-- Update data for currency IBC Products -- Sportsbook, Number Games, Virtual Sports, Keno, Virtual Sports 2, Lottery
UPDATE dbo.Products
SET ReleasedDate = '2018-09-01'
WHERE ProductId IN (1,4,5,6,7,8)