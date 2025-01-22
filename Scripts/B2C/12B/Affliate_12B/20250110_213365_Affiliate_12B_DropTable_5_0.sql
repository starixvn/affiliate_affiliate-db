/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250107@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Truncate all tables [RedmineID: #212201]
*/
USE Affiliate_12B
GO

DROP TABLE IF EXISTS [dbo].[ExchangeOanda]
GO
DROP TABLE IF EXISTS [dbo].[TpExchange]
GO
DROP TABLE IF EXISTS [dbo].[SystemSettings]
GO
DROP TABLE IF EXISTS [dbo].[AffTrans]
GO
DROP TABLE IF EXISTS [dbo].[AdminFavorite]
GO
DROP TABLE IF EXISTS [dbo].[AdminNotes]
GO
DROP TABLE IF EXISTS [dbo].[AffDetail]
GO
DROP TABLE IF EXISTS [dbo].[AffDomain]
GO
DROP TABLE IF EXISTS [dbo].[AffFunctionInfo]
GO
DROP TABLE IF EXISTS [dbo].[AffGroupHistory]
GO
DROP TABLE IF EXISTS [dbo].[AffGroupInfo]
GO
DROP TABLE IF EXISTS [dbo].[AffGroupPolicy]
GO
DROP TABLE IF EXISTS [dbo].[Affiliate_User]
GO
DROP TABLE IF EXISTS [dbo].[AffiliateCode]
GO
DROP TABLE IF EXISTS [dbo].[AffInfo]
GO
DROP TABLE IF EXISTS [dbo].[AffLoginInfo]
GO
DROP TABLE IF EXISTS [dbo].[AffMediaChannel]
GO
DROP TABLE IF EXISTS [dbo].[AffMediaLink]
GO
DROP TABLE IF EXISTS [dbo].[AffMemberPolicy]
GO
DROP TABLE IF EXISTS [dbo].[AffPayout]
GO
DROP TABLE IF EXISTS [dbo].[AffType]
GO
DROP TABLE IF EXISTS [dbo].[AffUserLoginInfo]
GO
DROP TABLE IF EXISTS [dbo].[ClickStatistics]
GO
DROP TABLE IF EXISTS [dbo].[ClickStatistics_bk]
GO
DROP TABLE IF EXISTS [dbo].[ClickStatisticsSum]
GO
DROP TABLE IF EXISTS [dbo].[CommGroup]
GO
DROP TABLE IF EXISTS [dbo].[CommGroupHistory]
GO
DROP TABLE IF EXISTS [dbo].[Deductions]
GO
DROP TABLE IF EXISTS [dbo].[DeductionSetting]
GO
DROP TABLE IF EXISTS [dbo].[DeductionSettingHistory]
GO
DROP TABLE IF EXISTS [dbo].[DomainControl]
GO
DROP TABLE IF EXISTS [dbo].[EmailHistory]
GO
DROP TABLE IF EXISTS [dbo].[Exchange]
GO
DROP TABLE IF EXISTS [dbo].[IPv4Addresses]
GO
DROP TABLE IF EXISTS [dbo].[LandingPage]
GO
DROP TABLE IF EXISTS [dbo].[LicenseeDomain]
GO
DROP TABLE IF EXISTS [dbo].[LogAction]
GO
DROP TABLE IF EXISTS [dbo].[LogType]
GO
DROP TABLE IF EXISTS [dbo].[Market]
GO
DROP TABLE IF EXISTS [dbo].[MediaGallery]
GO
DROP TABLE IF EXISTS [dbo].[MemberClickDetail]
GO
DROP TABLE IF EXISTS [dbo].[MemberInfo]
GO
DROP TABLE IF EXISTS [dbo].[MemberRemoval]
GO
DROP TABLE IF EXISTS [dbo].[Messages]
GO
DROP TABLE IF EXISTS [dbo].[News]
GO
DROP TABLE IF EXISTS [dbo].[On_User]
GO
DROP TABLE IF EXISTS [dbo].[Products]
GO
DROP TABLE IF EXISTS [dbo].[rptAffCommission]
GO
DROP TABLE IF EXISTS [dbo].[rptAffCommissionDetail]
GO
DROP TABLE IF EXISTS [dbo].[rptAffMonthly]
GO
DROP TABLE IF EXISTS [dbo].[rptMemberDaily]
GO
DROP TABLE IF EXISTS [dbo].[StraightSetting]
GO
DROP TABLE IF EXISTS [dbo].[StraightSettingHistory]
GO
DROP TABLE IF EXISTS [dbo].[SubAffDomain]
GO
DROP TABLE IF EXISTS [dbo].[TierSetting]
GO
DROP TABLE IF EXISTS [dbo].[TierSettingHistory]
GO
DROP TABLE IF EXISTS [dbo].[TransferBalanceHistory]
GO
DROP TABLE IF EXISTS [dbo].[TransType]
GO
DROP TABLE IF EXISTS [dbo].[UserLog_RunSP_Detail]
GO
DROP TABLE IF EXISTS [dbo].[Username_AutoIncrement]
GO
DROP TABLE IF EXISTS [dbo].[GroupType]
GO