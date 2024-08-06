/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240808@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new Column for bettrans_BTi2Test [RedmineId : #207119]
*/
USE Affiliate_12BET
GO

ALTER TABLE bettrans_BTi2Test ADD [Currency] VARCHAR(5)
GO

UPDATE APIProductSettingsTest WITH (UPDLOCK, ROWLOCK) -- Ignore some issues
SET SettingValue = '343475'
WHERE ProductId = 25 AND SettingName = 'LastQueueId'
GO