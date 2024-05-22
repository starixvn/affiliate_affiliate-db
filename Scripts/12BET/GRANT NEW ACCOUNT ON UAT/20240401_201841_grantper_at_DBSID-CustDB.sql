/*<info serverAlias="DBSID-CustDB"></info>*/
/*
	Created: 20240401@Eddie
	DB: DBSID-CustDB
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE CustDB
GO

GRANT SELECT ON [dbo].[Customer] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Exchange] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[custinfo] TO [wsv_afinet]
GO