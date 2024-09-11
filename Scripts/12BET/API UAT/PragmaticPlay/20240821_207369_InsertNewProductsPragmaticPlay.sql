/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240821@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

INSERT INTO dbo.ProductsTest([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (47, 'Pragmatic Play', 'PP', 0, 0, 1, 0, NULL, NULL) -- Note: ReleasedDate = GETDATE()
GO

INSERT INTO dbo.APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES  (47, 'ExcludeTicketStatus', 'Draw') -- Pragmatic Play
	   ,(47, 'LastQueueId', '0')		
	   ,(47, 'LaunchDate', '2024-08-01') -- Note: LaunchDate = GETDATE()
	   ,(47, 'SourceTable', 'APIProduct_ImportQueueTest')
	   ,(47, 'TimeZone', '0')
GO

INSERT INTO dbo.APIProductMappingSettingsTest([TpType], [SubItem], [ProductId])
VALUES (29, '', 47) --  Pragmatic Play
GO