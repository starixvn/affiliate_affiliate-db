/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230414@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "12Sapphire Skywind" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 17
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 32 AND SettingName = 'LastQueueId'
GO