/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240821@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

INSERT INTO dbo.ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (48, 'Diamond EVO', 'DE', 0, 0, 1, 0, NULL, NULL) -- Note: ReleasedDate = GETDATE()
GO

INSERT INTO dbo.APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES  (48, 'ExcludeTicketStatus', 'Draw') -- Diamond EVO
	   ,(48, 'LastQueueId', '0')		
	   ,(48, 'LaunchDate', '2024-08-01') -- Note: LaunchDate = GETDATE()
	   ,(48, 'SourceTable', 'APIProduct_ImportQueueTest')
	   ,(48, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettingsTest([TpType], [SubItem], [ProductId])
VALUES (27, '', 48) --  Diamond EVO
GO