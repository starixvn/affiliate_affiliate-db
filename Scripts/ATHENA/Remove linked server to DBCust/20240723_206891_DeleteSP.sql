/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20240723@Eddie
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: Remove linked server to DBCust [RedmineID: #206891]
*/

-- Rename SPs
EXEC sp_rename 'AffAdmin_AccountUpdPwd', 'DEL_AffAdmin_AccountUpdPwd'
GO
EXEC sp_rename 'AffAdmin_AccountUpdPwd_xtest', 'DEL_AffAdmin_AccountUpdPwd_xtest'
GO
EXEC sp_rename 'AffAdmin_AdminUpdPwd', 'DEL_AffAdmin_AdminUpdPwd'
GO
EXEC sp_rename 'AffAdmin_AdminUpdPwd_xtest', 'DEL_AffAdmin_AdminUpdPwd_xtest'
GO
EXEC sp_rename 'AffAdmin_ITAdminUser_Update', 'DEL_AffAdmin_ITAdminUser_Update'
GO
EXEC sp_rename 'AffAdmin_Con_AccountIns', 'DEL_AffAdmin_Con_AccountIns'
GO
EXEC sp_rename 'AffAdmin_Con_AccountIns_xtest', 'DEL_AffAdmin_Con_AccountIns_xtest'
GO
EXEC sp_rename 'AffAdmin_Con_AccountUpd', 'DEL_AffAdmin_Con_AccountUpd'
GO
EXEC sp_rename 'AffAdmin_Con_AccountUpd_xtest', 'DEL_AffAdmin_Con_AccountUpd_xtest'
GO
EXEC sp_rename 'AffAdmin_AdminUser_UpdateGroup', 'DEL_AffAdmin_AdminUser_UpdateGroup'
GO



-- Drop SPs
DROP PROCEDURE DEL_AffAdmin_AccountUpdPwd
GO
DROP PROCEDURE DEL_AffAdmin_AccountUpdPwd_xtest
GO
DROP PROCEDURE DEL_AffAdmin_AdminUpdPwd
GO
DROP PROCEDURE DEL_AffAdmin_AdminUpdPwd_xtest
GO
DROP PROCEDURE DEL_AffAdmin_ITAdminUser_Update
GO
DROP PROCEDURE DEL_AffAdmin_Con_AccountIns
GO
DROP PROCEDURE DEL_AffAdmin_Con_AccountIns_xtest
GO
DROP PROCEDURE DEL_AffAdmin_Con_AccountUpd
GO
DROP PROCEDURE DEL_AffAdmin_Con_AccountUpd_xtest
GO
DROP PROCEDURE DEL_AffAdmin_AdminUser_UpdateGroup
GO



