/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230313@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value [RedmineId : #180311]
*/

UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 9
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 10 AND SettingName = 'LastQueueId'
GO

