/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE Affiliate_12bet
GO

-- server: DB052
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
GRANT EXECUTE ON [dbo].[Aff_User_UserInfoUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecretKeyIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GeneralInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Country_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_User_CommSetting_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Affiliate_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberList_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistoryIns] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_TargetProduct_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaSize_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Domain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_LandingPage_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerStatistics_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Newsletter_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferPage_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_RateSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_FeedbackIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_FeedbackPopup_Check] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TargetCountry_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Language_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_CommGroup_Deductions_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_Login] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_PolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Check_AffBelongToUser] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateReport_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateReport_Detail_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliatePaymentRequest_Upd_Rollback] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLog_RunSP_Detail_WriteLog] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_StatementHistory_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateMarketingNote_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateMarketingNote_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateMarketingNote_Upd] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_LandingPage_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_LandingPage_ExcludedTargetCountry_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Newsletter_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Newsletter_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Newsletter_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_EmailHistory_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Exchange_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Exchange_Upd] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_Member_RemoveStatus_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ActiveMember_CheckStatus] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_RegisteredMember_Sel] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_12BETDomain_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_12BETDomain_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_12BETDomain_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_12BETDomain_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_DomainControl_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Domain_BlockTargetCountry_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_GeneralInfo_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Role_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Detail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_FunctionPermission_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_Market_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_RoleMarket_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_RoleMarket_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_RolePermission_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AdminUser_RolePermission_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Adjustment_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ViewLog_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_AffiliateLog_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_LogAction_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ProcessingRequest_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ProcessingRequest_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ProcessingRequest_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ProcessingRequest_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_ProcessingRequestDetail_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferPage_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferPage_Upd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferPage_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferAffiliate_Ins] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferAffiliate_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_OfferAffiliate_Del] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Feedback_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics_New] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Text_Sel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_APIProduct_ImportQueue] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_APIProduct_CallTimeIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_APIProduct_CallTimeByProductSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_3rdProduct_ImportQueueSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_3rdProduct_XmlDataByQueueIdSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_3rdProduct_TimeTrackerSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_NewAPIProduct_ImportQueue] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[IsZeroCommissionGroup] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetStartDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetEndDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMaxWinlostdate] TO [wsv_afinet]
GO
-- GRANT EXECUTE ON [dbo].[Aff_IPConvertToNumber] TO [wsv_afinet]
-- GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMinReportDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMoveBetsDay] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CountMember] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberPSP] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SplitIndex] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_HasDeduction] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMessageById] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeductionPercent] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_IP_DecToHex] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_IP_DivideBy16] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_IP_StringNumberToBase16] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ToString] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_f_IP_GetCountryCode] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetAffBalance] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLogType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeviceType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetFirstDayOfMonth] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLastDayOfMonth] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_Calc] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_UnCalc] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermission] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupAssign] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GenerateUsername] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermission] TO [wsv_afinet]
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
GRANT EXECUTE ON [dbo].[Aff_Admin_PolicySel] TO [wsv_afinetv]
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
GRANT EXECUTE ON [dbo].[Aff_Country_Sel] TO [wsv_afinetv]
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
GRANT EXECUTE ON [dbo].[Aff_User_CommSetting_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequest_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberList_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_TargetProduct_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_MediaSize_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Domain_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_User_LandingPage_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Admin_Banner_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_TargetCountry_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Language_Sel] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[IsZeroCommissionGroup] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetStartDate] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetEndDate] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMaxWinlostdate] TO [wsv_afinetv]
GO
-- GRANT EXECUTE ON [dbo].[Aff_IPConvertToNumber] TO [wsv_afinetv]
-- GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMinReportDate] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMoveBetsDay] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_CountMember] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberPSP] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_SplitIndex] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_HasDeduction] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_GetMessageById] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeductionPercent] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[f_IP_DecToHex] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[f_IP_DivideBy16] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[f_IP_StringNumberToBase16] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_ToString] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_f_IP_GetCountryCode] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetAffBalance] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLogType] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeviceType] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetFirstDayOfMonth] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLastDayOfMonth] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLog_RunSP_Detail_WriteLog] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermission] TO [wsv_afinetv]
GO
GRANT EXECUTE ON [dbo].[Aff_Commission_UnCalc] TO [wsv_afinetv]
GO
