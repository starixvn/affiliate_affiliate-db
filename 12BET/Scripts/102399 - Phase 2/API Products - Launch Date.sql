USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add launch date of AG Casino
*/

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (9, 'LaunchDate', '2018-11-01')