USE [Affiliate_12BET]
GO

/*
	Created: 20200108@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Set released date for LB Keno, GPI Lottery, VR Lottery, 12Topaz (ProductId: 20 21 22 23) is 2020 Jan 01
*/

UPDATE dbo.Products WITH (ROWLOCK)
SET IsTest = 0
WHERE ProductId IN (20, 21, 22, 23)
GO

UPDATE dbo.APIProductSettings WITH (ROWLOCK)
SET SettingValue = '2020-01-01'
WHERE ProductId IN (20, 21, 22, 23)
	AND SettingName = 'LaunchDate'
GO

