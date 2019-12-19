USE [Affiliate_12BET]
GO

/*
	Created: 20191201@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new setting for new products
*/

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
SELECT ProductId, SettingName, SettingValue
FROM (VALUES ('LastQueueId', '0'), ('LaunchDate', '2020-02-01'), ('SourceTable', 'APIProduct_ImportQueue')) AS Setting (SettingName, SettingValue)
	CROSS APPLY (VALUES (20), (21), (22), (23)) AS Product (ProductId)
