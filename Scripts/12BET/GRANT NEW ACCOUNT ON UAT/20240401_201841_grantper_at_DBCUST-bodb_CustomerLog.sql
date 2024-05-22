/*<info serverAlias="DBCUST-bodb_CustomerLog"></info>*/
/*
	Created: 20240401@Eddie
	DB: DBCUST-bodb_CustomerLog
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE bodb_CustomerLog
GO

GRANT EXECUTE ON [sb].[CustomerLog_SendMessage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_UpdMemComm_RunSP] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[WriteLog_UserLog_RunSP] TO [wsv_afinet]