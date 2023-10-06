/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230411@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting ExcludeTicketStatus for "12Jasper N2 Live" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = 'Draw'
WHERE ProductId = 34 AND SettingName = 'ExcludeTicketStatus'
GO