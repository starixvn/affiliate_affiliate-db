USE [Affiliate_12BET]
GO

/*
	Created: 20181030@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Products - Add new products - iSoftbet - OPUS - Crystal (GPI)
*/

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
SELECT 12, '12Crystal - GPI', '12GPI', 0, 0, 1, 0 UNION ALL
SELECT 13, '12Quartz - iSoftbet', '12ISB', 0, 0, 1, 0 UNION ALL
SELECT 14, '12Diamond - OPUS', '12OPUS', 0, 0, 1, 0