/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240731@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Regen data for BTi on UAT [RedmineId : #207119]
*/

UPDATE APIProduct_ImportQueueTest WITH (UPDLOCK, ROWLOCK) -- 9980
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE ProductId = 11
GO

UPDATE APIProductSettingsTest WITH (UPDLOCK, ROWLOCK)
SET SettingValue = '0'
WHERE ProductId = 11 AND SettingName = 'LastQueueId'
GO