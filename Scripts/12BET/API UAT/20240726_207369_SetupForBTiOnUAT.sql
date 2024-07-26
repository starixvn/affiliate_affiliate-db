/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240726@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for BTi on UAT [RedmineId : #207119]
*/

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (25, 'BTi', '12BTi', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (25, 'LastQueueId', '0')
	 , (25, 'LaunchDate', '2021-01-01')
	 , (25, 'SourceTable', 'APIProduct_ImportQueueTest')
GO