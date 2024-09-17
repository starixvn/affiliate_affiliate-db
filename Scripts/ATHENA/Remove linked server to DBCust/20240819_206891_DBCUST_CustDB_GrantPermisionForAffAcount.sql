/*<info serverAlias="DBCUST-CustDB"></info>*/
/*	
	Created: 20240819@Sally
	Task: Remove linked server to DBCUST [RedmineID: #206891]
	DB: DBCUST-bodb_Licensee
	- Grant permission for 'wsv_afinet' Account on CustDB
*/
USE CustDB
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_UserLog_Login_Wrapper] TO [wsv_afinet]