/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231108@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for Exchange [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 12
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 19 AND SettingName = 'LastQueueId'
GO
