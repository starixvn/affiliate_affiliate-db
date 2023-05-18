/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230512@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting ExcludeTicketStatus for "12Emerald - Playtech" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = 'Draw'
WHERE ProductId = 3 AND SettingName = 'ExcludeTicketStatus'
GO