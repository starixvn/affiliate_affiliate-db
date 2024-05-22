/*<info serverAlias="DBEXT-bodb02"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBEXT-bodb02
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE bodb02
GO

GRANT EXECUTE ON [dbo].[Acc_SiteDBConfigSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[strSplit] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelByUserName] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_DummyAccID] TO [wsv_afinet]
GO