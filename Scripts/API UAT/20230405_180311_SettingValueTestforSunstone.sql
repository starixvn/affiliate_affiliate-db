/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230405@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting LaunchDate for "12Sunstone EA" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = '2022-06-01'
WHERE ProductId = 35 AND SettingName = 'LaunchDate'
GO