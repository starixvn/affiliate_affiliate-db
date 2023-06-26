/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230626@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting ExcludeTicketStatus for "IM Esports" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = 'Draw'
WHERE ProductId = 31 AND SettingName = 'ExcludeTicketStatus'
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '-4'
WHERE ProductId = 31 AND SettingName = 'TimeZone'
GO