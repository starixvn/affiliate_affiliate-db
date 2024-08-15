/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240815@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup for GPI Lottery & Arcade on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (20, 'GPI Lottery & Arcade', '12LTGPI', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (20, 'ExcludeTicketStatus', 'Draw')
	 , (20, 'LastQueueId', '323447')
	 , (20, 'LaunchDate', '2020-01-01')
	 , (20, 'SourceTable', 'APIProduct_ImportQueueTest')
	 , (20, 'TimeZone', '8')
GO

INSERT INTO APIProductMappingSettingsTest([TpType], [SubItem], [ProductId])
VALUES (7, '001001', 20)
GO