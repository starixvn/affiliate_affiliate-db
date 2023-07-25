/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230725@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "12Crystal - GPI" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 7 AND SubItem IN ('001002', '001003')
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 12 AND SettingName = 'LastQueueId'
GO