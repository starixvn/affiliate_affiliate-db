/*<info serverAlias="DBAFF-Affiliate_Athena000"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBAFF - Affiliate_Athena000,Affiliate_Aoncash,Affiliate_ItcBet,Affiliate_MacauBet,Affiliate_Spondemo,Affiliate_9Bet
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/

GRANT EXECUTE ON [dbo].[Aff_Link_AffiliateInsClickStatistics] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Banner_UpdateStatistic] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Banner_SelInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberInfoGetMissingCreatedDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoImportData] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyImportData] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyTransactionImportData] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_aff_DailyImportExchange] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrentDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyListSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskLogUpdStatus] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskLogIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskDetailSelByName] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLastDayOfMonth] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetFirstDayOfMonth] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetEndDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSmallDatetime] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetStartDate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_IPConvertToNumber] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Row_Count] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[parseURL] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[NumberConvertToIP] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[IPConvertToNumber] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[InitCap] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Date_Only] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_ToString] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_SplitIndex] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_f_GetDeductionPercent] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayerCurrencyByAffId] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_f_HasDeduction] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_IsProductInGroupOfAff] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[IsZeroCommissionGroup] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_HasDeduction] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSystemCurrencyID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMaxWinlostdate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetLogType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSettingValue] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetQMTurnOver] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetProductID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberWinlost] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetDeductionPercent] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetCurrencyCode] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetAffBalance] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CountMember] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GetGroupItID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetExchangeID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetExchangeRate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberPSP] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[GetCountryIDFromIP] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetAffDeductionAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedAmount] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetDefaultProductCommission] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EmailHistoryIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsSel_New] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsDetail_New] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSelType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_DomainAffClientSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ProductSelByAffID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateUpdInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelEditInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SystemSettingsSelByType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelDBTime] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetAllAffSystemSettings] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelByPage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsDetailBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestSelInfoByAff] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PlayerPayoutInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_MemberListSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_StatisticsSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CommGroupSelDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecureLoginUpdate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Recheckin] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Logout] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateForgotPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateRecoverPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateInternalLogin] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecureUpdPasswordInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SecureUpdPasswordUpdate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateStatementHistorySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EarningSelDaily] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EarningSelDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Logout] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AdminUpdPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ExchangeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ExchangeAutoRefreshUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ExchangeUpdate] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CopyRateFromMarket] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetDefaultPSPExchange] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HomeGeneralInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserOnlineList] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelListNormal] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionSettingSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupList_SettingDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GroupSettingSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupAssign] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroup_SelActiveList] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_FavoriteDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_FavoriteIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelFavorite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_EmailHistorySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_EmailHistoryDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberListSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetMemberDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AccountTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CheckMemberExist] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CustomerInsMemberManually] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdAccountType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetLicenseeSupportedCurrencies] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemAllSupportedCurrencies] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSupportedCurrencies] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateCurrenciesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelDBTime] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AdminSupportedLanguagesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelByName] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelByType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CountrySelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CountryUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CountryIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CountryDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CountrySelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductSelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductSelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageSelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_LanguageSelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeSelAll] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeSelByID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsExchange] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberSupportedLanguagesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PlayersCurrenciesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestSelList] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestSelDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PlayerPayoutInfoSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateCommissionReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MonthlyTransfer] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_IsMonthlyTransfer] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequest_InProgress] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainAffSelById] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSelById] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlSelById] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_AccountUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_SelByCustID] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_AccountIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AccountUpdPwd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_GroupInfoIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_GroupInfoUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_GroupInfoDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_GroupPolicySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserCurrencySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserCurrencyIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSelType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSelDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelGeneralInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_StatisticsSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdStatus] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdClosedStatus] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_PreferLangUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUnlock] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSupportedLanguagesSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_UpdAffType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_TransTypeSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_StatementHistorySel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliatePaymentMethodSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelEditInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdInfo] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_NoteSel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_NoteIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_NoteUpd] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_NoteDel] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelLogType] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelLog] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CustomerSelBalBF] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AdjustmentIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelBySite] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsDetail] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CompanyWinlossReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CompanyWinLossByProductReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberStatisticsReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateWinLossReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateWinLossByProductReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberWinLossReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberWinLossByProductReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_GenUsername] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_MonthlyEarning] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupAssign] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetMemberStatistics] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_ReCalculateAffSumData] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[RefResources] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[AdminUser] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[News] TO [wsv_afinet]
GO