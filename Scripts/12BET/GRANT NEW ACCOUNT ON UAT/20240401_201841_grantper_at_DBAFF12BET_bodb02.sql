/*<info serverAlias="DBAFF12BET-bodb02"></info>*/
/*
	Created: 20240401@Eddie
	DB: DBAFF12BET-bodb02
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE bodb02
GO

-- server: DB052,DB053
GRANT SELECT ON [dbo].[Customer] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[CustInfo] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Exchange] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[match14] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[match14] TO [wsv_afinetv]
GO
