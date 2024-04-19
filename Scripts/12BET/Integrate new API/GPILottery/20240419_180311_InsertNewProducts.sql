/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240419@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (20, 'ExcludeTicketStatus', 'Draw')-- GPI Lottery & Arcade
	   ,(20, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId)
VALUES (7, '001001', 20)--  GPI Lottery & Arcade
GO