/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230411@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting TimeZone for "VR Lottery" [RedmineId : #180311]
*/
UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 21 AND SettingName = 'TimeZone'
GO