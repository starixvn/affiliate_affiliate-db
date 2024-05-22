/*<info serverAlias="DBLIC-bodb_licenseeReport"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBLIC-bodb_licenseeReport
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE bodb_licenseeReport
GO

GRANT SELECT ON [dbo].[rptLicWinloss2] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[rptLicWinloss_old] TO [wsv_afinet]
GO