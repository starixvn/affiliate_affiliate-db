/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240911@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

INSERT INTO ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (23, '12Topaz', '12TP', 0, 0, 1, 0, NULL, NULL)
GO

INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES (23, 'ExcludeTicketStatus', 'Draw')-- 12Topaz
	   ,(23, 'LastQueueId', '482793')
	   ,(23, 'LaunchDate', '2020-01-01')
	   ,(23, 'SourceTable', 'APIProduct_ImportQueueTest')
	   ,(23, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId)
VALUES (18, '', 23)--  12Topaz
GO