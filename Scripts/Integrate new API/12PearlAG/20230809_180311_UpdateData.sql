/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230809@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update Data for "12Pearl AG" [RedmineId : #180311]
*/
UPDATE dbo.Products WITH(ROWLOCK, UPDLOCK)
SET ProductName = '12Pearl - AG'
WHERE ProductName = '12Pearl - AG Casino'
GO

UPDATE dbo.APIProductSettings WITH(ROWLOCK, UPDLOCK)
SET SettingValue = 'APIProduct_ImportQueue'
WHERE ProductId = 9 AND SettingName = 'SourceTable'
GO