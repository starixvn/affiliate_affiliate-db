/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" ></info>*/
/*
	Created: 20240326@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Switch to use new account [Redmine: #201841]
		- Grant Permission SP/Func
		
*/ 
-- Run On DB052/DB053
USE Affiliate_N8G
GO
GRANT EXECUTE ON [dbo].[Aff_User_Login_UserInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Login_ResultUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Recheckin] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_VerificationInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_VerificationUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_VerificationSuccessIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_UserInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_UserInfoUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecretKeyIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GeneralInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ChangePassword] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateDomain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateDomain_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateDomain_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateDomain_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LicenseeDomain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LicenseeDomain_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LicenseeDomain_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LicenseeDomain_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_SubAffiliateDomain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_SubAffiliateDomain_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_SubAffiliateDomain_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_SubAffiliateDomain_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_GeneralInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Currency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentCurrency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicyUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminSelByGroupID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminUpdClosed] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminInsFromExisted] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminSelByCustID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminGroupUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicySelByCustID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicyUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_Batch_AdminPolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatistics_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Get_GeneralAffInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfo_Import] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_GetSetting] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_API_AffiliateInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_API_AffiliateDetailInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_Calc] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_UnCalc] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_Calc] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_UnCalc] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicyIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GenerateUsername] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLog_RunSP_Detail_WriteLog] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GenerateUsername] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLog_RunSP_Detail_WriteLog] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_ExchangeRate_Sel] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_Get_SecurityQuestions] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_GetBalBroughtForward] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMessageById] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMinReportDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetSetting] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaCategory_Sel] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaSize_Sel] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaType_Sel] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_StringSplit] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_TpExchange_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeviceType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_IPConvertToNumber] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SplitIndex] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ToString] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Aff_f_ExchangeRate_Sel] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_Get_SecurityQuestions] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_GetBalBroughtForward] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMessageById] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMinReportDate] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetSetting] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaCategory_Sel] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaSize_Sel] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_MediaType_Sel] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_StringSplit] TO [wsv_afinetv]
GO
GRANT SELECT ON [dbo].[Aff_f_TpExchange_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeviceType] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_IPConvertToNumber] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_SplitIndex] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ToString] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [wsv_afinetv]
GO