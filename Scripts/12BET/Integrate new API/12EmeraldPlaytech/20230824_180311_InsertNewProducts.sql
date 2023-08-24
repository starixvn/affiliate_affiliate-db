/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230824@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]

*/
INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (3, 'ExcludeTicketStatus', 'Draw')-- 12Emerald Playtech
	   ,(3, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId )
VALUES (1, '', 3)--  12Emerald Playtech
GO