/*<info serverAlias="DBLOG-bodb_CustomerLog"></info>*/
/*	
	Created: 20240819@Sally
	Task: Remove linked server to DBLOG [RedmineID: #206891]
	DB: DBLOG-bodb_CustomerLog
	- Grant permission for 'wsv_afinet' Account on bodb_CustomerLog
*/
USE bodb_CustomerLog
GO

CREATE USER [wsv_afinet] FOR LOGIN [wsv_afinet] WITH DEFAULT_SCHEMA=[dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_WebAPI_WriteLog] TO [wsv_afinet]
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [wsv_afinet]