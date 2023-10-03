/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230414@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting ExcludeTicketStatus and TimeZone for "12Sapphire Skywind" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = 'Draw'
WHERE ProductId = 32 AND SettingName = 'ExcludeTicketStatus'
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '8'
WHERE ProductId = 32 AND SettingName = 'TimeZone'
GO