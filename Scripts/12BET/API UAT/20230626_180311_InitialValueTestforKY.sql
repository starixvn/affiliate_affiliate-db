/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230626@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "KY Gaming" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 19
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 24 AND SettingName = 'LastQueueId'
GO