USE Affiliate_Licensee
 GO
-- Clean data 
truncate table UserLog_IISErr
truncate table TaskLog
truncate table On_User
truncate table News
truncate table MemberRemoval
truncate table MemberInfo
truncate table ClickStatistics
truncate table Branch
truncate table BankTrans
truncate table AffTrans
truncate table AffPayout
truncate table AffInfo
truncate table AffGroupHistory
truncate table AffDetail
truncate table AffDailySummary
truncate table AffDaily
truncate table AffCommission
truncate table AdminNotes
truncate table AdminFavorite
truncate table AdminBranch
truncate table GroupSettingHistory
truncate table ExchangeDaily
truncate table ErrorLog
truncate table EmailHistory
truncate table DeductionSettingHistory
truncate table CommGroupHistory
truncate table UserLog
truncate table MemberDailyTransaction
truncate table MemberDaily
truncate table ClickStatisticsSum
truncate table ClickStatistics_bk
truncate table MemberDailyRemoved
truncate table UserLog_RunSP
truncate table Banners

-- delete redundant data


delete RefResources where RefID='News';
delete bannertypes where Type='Size';
-- Reset Commission Group Settingdelete CommGroup where GroupId > 102
delete GroupSetting where GroupId > 102
delete GroupSettingHistory where GroupId > 102
delete DeductionSetting where GroupId > 102
delete DeductionSettingHistory where GroupId > 102
delete AffGroupHistory where GroupId > 102
delete [dbo].[CommGroup] where GroupId > 102

--Update exchange auto refresh
update exchange set IsAutoRefresh = 1
