/*<info serverAlias="DBRPT-bodb_report"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBRPT-bodb_report
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE bodb_report
GO

GRANT SELECT ON [dbo].[rptdepwinlost] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[rptDepWinlost_bk] TO [wsv_afinet]
GO