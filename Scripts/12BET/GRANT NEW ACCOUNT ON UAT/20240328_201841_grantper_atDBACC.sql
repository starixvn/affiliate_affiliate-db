/*<info serverAlias="DBACC-bodb02"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBACC-bodb02
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE bodb02
GO

GRANT EXECUTE ON [dbo].[Aff_PlayersFundingSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeDailyOanda_SelByDate] TO [wsv_afinet]
GO