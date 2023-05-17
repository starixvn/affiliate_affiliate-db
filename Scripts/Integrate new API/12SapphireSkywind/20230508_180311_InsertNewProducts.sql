/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230508@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (32, 'ExcludeTicketStatus', 'Draw')-- 12Sapphire Skywind
	   ,(32, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId )
VALUES (17, '', 32)--  12Sapphire Skywind
GO