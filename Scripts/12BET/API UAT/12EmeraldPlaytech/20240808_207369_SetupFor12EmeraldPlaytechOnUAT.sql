/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240808@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for 12Emerald Playtech on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (3, '12Emerald - Playtech', 'PTCS', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (3, 'LastQueueId', '0')
	 , (3, 'LaunchDate', '2013-01-18')
	 , (3, 'SourceTable', 'APIProduct_ImportQueueTest')
GO