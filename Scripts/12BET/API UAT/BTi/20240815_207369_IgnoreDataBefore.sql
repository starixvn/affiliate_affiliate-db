/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240815@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Ignore Data Before on UAT [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

UPDATE APIProductSettingsTest WITH (UPDLOCK, ROWLOCK)
SET SettingValue = '461940'
WHERE ProductId = 25 AND SettingName = 'LastQueueId'
GO