/*<info serverAlias="DBCUST-CustDB"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBCUST-CustDB
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

USE CustDB
GO

GRANT EXECUTE ON [dbo].[Acc_SiteDBConfigSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag_Cust] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag_Cust_Switch] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Dot_Dep_CustomerInsMember_Ag_Cust_Main] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_f_Get_MsgNamebyMsgID] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Customer] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberComm_Direct] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberComm_Main] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Acc_Dep_CustSetting_Game_Check] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Acc_Dep_CustSetting_Check] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberBAStatus] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberBAComm] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberBAPositionTakingDCS] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_EnableDisableBAMember] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBACust_Playerdiscount_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_AGC_Customer_SetDefaultSetting] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_3rdProductCustomerSetDefaultSetting] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Acc_WriteLog_UserLog_RunSP_Wrapper] TO [wsv_afinet]
GO