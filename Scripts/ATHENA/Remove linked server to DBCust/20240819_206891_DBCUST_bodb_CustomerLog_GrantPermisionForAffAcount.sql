/*<info serverAlias="DBCUST-bodb_CustomerLog"></info>*/
/*	
	Created: 20240819@Sally
	Task: Remove linked server to DBCUST [RedmineID: #206891]
	DB: DBCUST-bodb_CustomerLog
	- Grant permission for 'wsv_afinet' Account on bodb_CustomerLog
*/

USE bodb_CustomerLog
GO

GRANT SELECT ON [dbo].[UserLog_Login_Aff] TO [wsv_afinet]
GRANT INSERT ON [dbo].[UserLog_Login_Aff] TO [wsv_afinet]