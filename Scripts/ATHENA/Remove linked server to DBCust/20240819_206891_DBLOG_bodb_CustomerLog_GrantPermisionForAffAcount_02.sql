/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
/*	
	Created: 20240819@Sally
	Task: Remove linked server to DBLOG [RedmineID: #206891]
	DB: DBLOG-bodb_CustomerLog
	- Grant permission for 'wsv_afinet' Account on bodb_CustomerLog
*/
USE bodb_CustomerLog
GO

GRANT SELECT ON [dbo].[UserLog_Login_Aff] TO [wsv_afinet]
GRANT INSERT ON [dbo].[UserLog_Login_Aff] TO [wsv_afinet]