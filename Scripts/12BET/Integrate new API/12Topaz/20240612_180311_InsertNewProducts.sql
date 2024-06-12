/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240612@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (23, 'ExcludeTicketStatus', 'Draw')-- 12Topaz
	   ,(23, 'TimeZone', '0')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId)
VALUES (18, '', 23)--  12Topaz
GO