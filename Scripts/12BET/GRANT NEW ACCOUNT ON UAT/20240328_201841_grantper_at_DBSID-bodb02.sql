/*<info serverAlias="DBSID-bodb02"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBSID-bodb02
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE bodb02
GO

GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePaymentRequest_Approve] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_Get_SiteDBGroupID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Get_Bettrans_TransID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceCreditUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceDebitUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceDebit_GeneralWalletUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceDebit_GeneralWalletUpd_new] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceDebit_BonusWalletUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceCredit_GeneralWalletUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceCredit_BonusWalletUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_BalanceReinitData] TO [wsv_afinet]
GO