/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231108@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting value for product Exchange [RedmineId : #180311]
*/
INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES (19, '3rdProductId', '31')		
       ,(19, 'ExcludeTicketStatus', 'Draw')		
	   ,(19, 'LastQueueId', '0')		
	   ,(19, 'LaunchDate', '2019-10-01')		
	   ,(19, 'SourceTable', 'APIProduct_ImportQueueTest')
	   ,(19, 'TimeZone', '-4')
GO

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId )
VALUES (12, '', 19)
GO