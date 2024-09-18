/*<info serverAlias="DBSID-CustDB"></info>*/
/*	
	Created: 20240918@Sally
	Task: Remove linked server to DBCUST [RedmineID: #206891]
	DB: DBSID-CustDB
	- Grant permission for 'wsv_afinet' Account on DBSID-CustDB
*/
USE CustDB
GO
GRANT EXECUTE ON [dbo].[Acc_SiteDBConfigSel] TO [wsv_afinet]

