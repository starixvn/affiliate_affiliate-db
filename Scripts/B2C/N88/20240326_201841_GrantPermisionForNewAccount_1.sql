/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" ></info>*/
/*
	Created: 20240326@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Switch to use new account [Redmine: #201841]
		- Grant Permission SP/Func
		
*/ 
-- Run On DB052/DB053

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
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Rpt_MarketingPage_Statistics] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ForgotPassword] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_RecoverPassWord] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_StatementHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductList_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_DailyEarning_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUser_ExtraUserInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SubAffiliate_Commission_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentMethod_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Affiliate_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Get_GeneralAffInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Rpt_Commission] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecurityQuestions_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Overview_PlayersDetail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Overview_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Overview_Summary_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_LoginInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCategory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Market_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCurrency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaType_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaSize_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Domain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SubAffiliateDomain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Overview_SubAffiliate_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffMediaChannel_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffMediaChannel_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffMediaChannel_Statistics] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffMediaLink_ToggleChannel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TransferBalanceHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_TransferBalanceInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TransferBalanceHistory_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TransferBalanceHistory_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SessionIdSel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Login_UserInfoSel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Login_ResultUpd] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Recheckin] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_UserInfoSel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GeneralInfo_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Rpt_MarketingPage_Statistics] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_StatementHistory_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductList_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_DailyEarning_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUser_ExtraUserInfoSel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCategory_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Market_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCurrency_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaType_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaSize_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Domain_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SubAffiliateDomain_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Market_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Affiliate_Approved] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUsername_SearchEx] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Statistics_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateOnlineList_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductList_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Deductions_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroup_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroupNormal_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Assign] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_PolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermission] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Recheckin] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Login] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_PolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateReport_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateReport_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_PlayerReport_GGR] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TransferBalanceHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_GetSetting] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Affiliate_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Affiliate_Favorite_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Affiliate_Password_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePaymentRequest_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePaymentRequest_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePaymentRequest_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentMethod_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_StatementHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_DailyEarning_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_DailyEarning_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_PlayersDetail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Member_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateNote_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateNote_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateNote_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateNote_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateLog_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LogType_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelBalBF] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateAdjustment_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePreferredLanguage_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateStatus_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateClosed_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateAffType_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateInfo_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayerUsername_CheckIsValid] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SubAffiliate_Commission_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_TransferLimit_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_TransferLimit_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCategory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaCurrency_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaSize_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Message_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Message_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Message_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Message_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MemberList_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Player_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Member_RemoveStatus_Upd] TO [wsv_afinet]
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