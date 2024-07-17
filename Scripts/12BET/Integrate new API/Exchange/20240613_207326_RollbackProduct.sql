/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240716@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Delete setting for Exchange product [RedmineId : #207119]
*/
UPDATE aps WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '3rdProducts'
FROM dbo.APIProductSettings aps
WHERE ProductId = 19 AND SettingName = 'SourceTable'
GO

UPDATE aps WITH (ROWLOCK, UPDLOCK)
SET SettingValue = '1184063'
FROM dbo.APIProductSettings aps
WHERE ProductId = 19 AND SettingName = 'LastQueueId'
GO

DELETE dbo.APIProductSettings WITH (ROWLOCK, UPDLOCK)
WHERE ProductId = 19 AND SettingName IN ('ExcludeTicketStatus', 'TimeZone')
GO

DELETE dbo.APIProductMappingSettings WITH (ROWLOCK, UPDLOCK)
WHERE ProductId = 19
GO

DELETE rpt WITH (ROWLOCK, UPDLOCK)-- having 1191 rows
FROM dbo.rptMemberDaily rpt   
WHERE rpt.ProductId = 19 AND rpt.WinlostDate >= '2024-07-01 00:00:00'
GO