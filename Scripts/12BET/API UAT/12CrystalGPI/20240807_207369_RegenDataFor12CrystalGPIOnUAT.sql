/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240807@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data for 12Crystal GPI on UAT [RedmineId : #207119]
*/
UPDATE APIProductSettingsTest WITH (UPDLOCK, ROWLOCK)
SET SettingValue = '0'
WHERE ProductId = 12 AND SettingName = 'LastQueueId'
GO