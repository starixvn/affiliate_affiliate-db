USE [Affiliate_12BET]
GO

/*
	Created: 20181030@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Set isTest = 0 of AG Casino
*/

UPDATE dbo.Products WITH (ROWLOCK, UPDLOCK)
SET IsTest = 0
WHERE ProductId = 9