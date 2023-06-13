/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230613@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (25, 'ExcludeTicketStatus', 'Draw')-- BTi
	   ,(25, 'TimeZone', '0')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId )
VALUES (15, '', 25)--  BTi
GO