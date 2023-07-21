/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230721@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add setting value for product '12Crystal - GPI' [RedmineId : #180311]
*/
INSERT INTO dbo.APIProductSettingsTest (ProductId, SettingName, SettingValue)
VALUES (12, 'ExcludeTicketStatus', 'Draw')--   				12Crystal  GPI
	   ,(12, 'LastQueueId', '0')-- 							12Crystal  GPI
	   ,(12, 'LaunchDate', '2019-01-01')-- 					12Crystal  GPI
	   ,(12, 'SourceTable', 'APIProduct_ImportQueueTest')--	12Crystal  GPI
	   ,(12, 'TimeZone', '-4')-- 							12Crystal  GPI
GO

INSERT INTO dbo.APIProductMappingSettingsTest (TpType, SubItem, ProductId )
VALUES (7, '001002', 12)--  12Crystal  GPI
	   ,(7, '001003', 12)-- 12Crystal  GPI
GO