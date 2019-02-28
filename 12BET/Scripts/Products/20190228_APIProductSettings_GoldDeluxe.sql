USE [Affiliate_12BET]
GO

/*
	Created: 20190228@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new setting for Gold Deluxe
*/

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
SELECT 17, '3rdProductId', '11' UNION ALL
SELECT 17, 'LastQueueId', '0' UNION ALL
SELECT 17, 'LaunchDate', '2019-03-01' UNION ALL
SELECT 17, 'SourceTable', '3rdProducts'