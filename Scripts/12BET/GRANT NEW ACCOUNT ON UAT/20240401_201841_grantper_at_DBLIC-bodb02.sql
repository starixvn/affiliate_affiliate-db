/*<info serverAlias="DBLIC-bodb02"></info>*/
/*
	Created: 20240401@Eddie
	DB: DBLIC-bodb02
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE bodb02
GO

GRANT SELECT ON [dbo].[strSplit] TO [wsv_afinet]
GO