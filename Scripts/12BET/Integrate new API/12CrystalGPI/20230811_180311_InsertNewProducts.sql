/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230811@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (12, 'ExcludeTicketStatus', 'Draw')-- 12Crystal	GPI
	   ,(12, 'TimeZone', '-4')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId)
VALUES (7, '001002', 12)--  12Crystal GPI (Live)
	  ,(7, '001003', 12)--  12Crystal GPI (Slot)
GO