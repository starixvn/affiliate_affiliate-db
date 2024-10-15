/*<info serverAlias="DBLOG-bodb02"></info>*/
/*	
	Created: 20240819@Sally
	Task: Remove linked server to DBCUST [RedmineID: #206891]
	DB: DBLOG-bodb02
	- Grant permission for 'wsv_afinet' Account on bodb02
*/
USE bodb02
GO

CREATE USER [wsv_afinet] FOR LOGIN [wsv_afinet] WITH DEFAULT_SCHEMA=[dbo]
GO

GRANT SELECT ON [dbo].[Customer] TO [wsv_afinet]