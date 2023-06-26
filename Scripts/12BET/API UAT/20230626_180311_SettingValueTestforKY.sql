/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230626@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting ExcludeTicketStatus for "KY Gaming" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = 'Draw'
WHERE ProductId = 24 AND SettingName = 'ExcludeTicketStatus'
GO