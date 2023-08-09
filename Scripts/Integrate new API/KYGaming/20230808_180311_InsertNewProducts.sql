/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230808@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (24, 'ExcludeTicketStatus', 'Draw')-- KY Gaming
	   ,(24, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId)
VALUES (19, '', 24)--  KY Gaming
GO