/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20241007@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #207119]

*/
USE Affiliate_12BET
GO

INSERT INTO dbo.Products([ProductId], [ProductName], [ProductPrefix], [IsIBC], [TransferType], [Enabled], [IsTest], [EndOfSupportDate], [ReleasedDate])
VALUES (47, 'Pragmatic Play', 'PP', 0, 0, 1, 0, NULL, NULL) -- Note: ReleasedDate = NULL 
GO

INSERT INTO dbo.APIProductSettings([ProductId], [SettingName], [SettingValue])
VALUES  (47, 'ExcludeTicketStatus', 'Draw') -- Pragmatic Play
	   ,(47, 'LastQueueId', '0')		
	   ,(47, 'LaunchDate', '2024-10-01') -- Note: early month
	   ,(47, 'SourceTable', 'APIProduct_ImportQueue')
	   ,(47, 'TimeZone', '0')
GO

INSERT INTO dbo.APIProductMappingSettings([TpType], [SubItem], [ProductId])
VALUES (29, '', 47) --  Pragmatic Play
GO