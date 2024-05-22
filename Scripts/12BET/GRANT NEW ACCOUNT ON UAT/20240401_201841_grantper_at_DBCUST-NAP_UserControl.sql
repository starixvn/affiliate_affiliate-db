/*<info serverAlias="DBCUST-NAP_UserControl"></info>*/
/*
	Created: 20240401@Eddie
	DB: DBCUST-NAP_UserControl
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE NAP_UserControl
GO

GRANT EXECUTE ON [dbo].[Acc_Con_CheckPermission] TO [wsv_afinet]
GO