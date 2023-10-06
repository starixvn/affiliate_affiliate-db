/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230322@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Setting initial value for "12Jasper N2 Live" [RedmineId : #180311]
*/
UPDATE dbo.APIProduct_ImportQueueTest
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 22
GO

UPDATE dbo.APIProductSettingsTest
SET SettingValue = '0'
WHERE ProductId = 34 AND SettingName = 'LastQueueId'
GO

