/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240709@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for 12Pearl AG on UAT [RedmineId : #207119]
*/

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (9, '12Pearl - AG', '12AG', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (9, '3rdProductId', '10')
	 , (9, 'LastQueueId', '0')
	 , (9, 'LaunchDate', '2018-11-01')
	 , (9, 'SourceTable', '3rdProducts')
GO