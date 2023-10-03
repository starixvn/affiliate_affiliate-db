/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230811@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update Data To Get LastQueueId [RedmineId : #180311]

*/
UPDATE dbo.APIProduct_ImportQueue WITH (ROWLOCK, UPDLOCK) -- having 982 rows
SET FinishedTime = NULL, WinlostDate = NULL, LogDesc = NULL
WHERE TpType = 7 AND SubItem IN ('001002', '001003')
GO


UPDATE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '9199000'
WHERE ProductId = 12 AND SettingName = 'LastQueueId'
GO