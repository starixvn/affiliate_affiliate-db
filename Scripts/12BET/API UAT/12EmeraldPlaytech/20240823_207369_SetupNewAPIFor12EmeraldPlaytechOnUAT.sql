/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240823@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setup new API for 12Emerald Playtech on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

INSERT INTO APIProductSettingsTest([ProductId], [SettingName], [SettingValue])
VALUES (3, 'ExcludeTicketStatus', 'Draw') -- 12Emerald Playtech
	 , (3, 'TimeZone', '8')
GO

INSERT INTO dbo.APIProductMappingSettingsTest([TpType], [SubItem], [ProductId])
VALUES (1, '', 3) --  12Emerald Playtech
GO