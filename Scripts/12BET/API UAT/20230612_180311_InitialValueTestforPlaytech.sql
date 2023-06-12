/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230612@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "12Emerald - Playtech" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 1
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 3 AND SettingName = 'LastQueueId'
GO