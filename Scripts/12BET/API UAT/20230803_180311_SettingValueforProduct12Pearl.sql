/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230803@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting value for product '12Pearl - AG'[RedmineId : #180311]
*/
INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES (9, '3rdProductId', '10')--   				12Pearl  AG
	   ,(9, 'ExcludeTicketStatus', 'Draw')--   				12Pearl  AG
	   ,(9, 'LastQueueId', '0')-- 							12Pearl  AG
	   ,(9, 'LaunchDate', '2018-11-01')-- 					12Pearl  AG
	   ,(9, 'SourceTable', 'APIProduct_ImportQueueTest')--	12Pearl  AG
	   ,(9, 'TimeZone', '-4')-- 							12Pearl  AG
GO

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId )
VALUES (4, '', 9)--  12Pearl  AG
GO