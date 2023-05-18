/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230411@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "VR Lottery" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 16
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 21 AND SettingName = 'LastQueueId'
GO