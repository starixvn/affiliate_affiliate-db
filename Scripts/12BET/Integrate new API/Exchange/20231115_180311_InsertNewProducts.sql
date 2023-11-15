/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20231115@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Insert new products [RedmineId : #180311]
*/
UPDATE aps WITH (ROWLOCK, UPDLOCK)
SET SettingValue = 'APIProduct_ImportQueue'
FROM dbo.APIProductSettings aps
WHERE ProductId = 19 AND SettingName = 'SourceTable'
GO

INSERT INTO dbo.APIProductSettings (ProductId, SettingName, SettingValue)
VALUES (19, 'ExcludeTicketStatus', 'Draw')
	   ,(19, 'TimeZone', '-4')
GO

INSERT INTO dbo.APIProductMappingSettings (TpType, SubItem, ProductId )
VALUES (12, '', 19)
GO