/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231018@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update LastQueueId for "12Crystal GPI" [RedmineId : #180311]
*/
UPDATE ps WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '9276664'
FROM APIProductSettings ps
WHERE ProductId = 12 AND SettingName = 'LastQueueId'
GO