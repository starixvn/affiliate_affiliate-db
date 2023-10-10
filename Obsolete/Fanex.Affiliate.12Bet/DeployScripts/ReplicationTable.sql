* Tables that have primary key:

AdminFavorite (AdminID,AffID)
AdminNotes (NoteID)
AffCommission (RefID)
AffDetail (AffID)
AffGroupHistory (AffID,MonthDate,GroupID)
AffInfo (AffID)
AffPayout (RefID)
AffTrans (TransID)
Banners (BannerID)
ClickStatisticsSum  (AffID,TrackingID,Date,IsForMonth)
CommGroup (GroupID)
CommGroupHistory (GroupID,MonthDate)
DeductionSetting (GroupID,DeductionID)
DeductionSettingHistory (GroupID,MonthDate,DeductionID)
DeductionType (DTypeID)
EmailHistory (MID)
Exchange(UpdatedTime,ExchangeID)
Exchange_Current (ExchangeID)
GroupSetting(GroupID,SportType,TierID)
GroupSettingHistory(GroupID,SportType,TierID,MonthDate)
LogType(TypeID)
MemberDaily (WinlostDate,IBCCustID,SportType)
MemberDailyRemoved(WinlostDate,IBCCustID,SportType)
MemberInfo(IBCCustID)
MemberRemoval (IBCCustID)
News (MsgID)
Ref (RefName)
SportType (SportID)
SystemSettings (SID)
TrackingCode (TrackingID)
TransType (TypeID)



* Tables without primary key:

UserLog
BannerTypes
ClickStatistics
ClickStatistics_bk
UserLog_Login
UserLog_RunSP
BankTrans