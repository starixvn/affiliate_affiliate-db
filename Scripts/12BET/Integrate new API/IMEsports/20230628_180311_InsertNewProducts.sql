/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230628@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (31, 'ExcludeTicketStatus', 'Draw')-- IM Esports
	   ,(31, 'TimeZone', '-4')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId)
VALUES (14, '', 31)--  IM Esports
GO