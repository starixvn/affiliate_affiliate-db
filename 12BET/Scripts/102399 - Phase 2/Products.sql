USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Integrate new products - phase 2
		- AG Casino
		- EBet
		- Betsoft
*/

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest)
VALUES
	(9, '12Pearl - AG Casino', '12AG', 0, 1, 1),
	(10, '12Opal - EBet', '12EB', 0, 1, 1),
	(11, '12Amber - Betsoft', '12BS', 0, 1, 1)