use [Affiliate_Licensee]

delete AffDetail where AffID not in (select AffID from AffInfo)

update AffInfo with (rowlock,updlock)
set GroupID=101 where status='approved'

update AffInfo with (rowlock,updlock)

set GroupID=102 where status='closed'
-- import testing data

-- update testing data
update AffInfo with(rowlock,updlock) set AffType=1, Currency= 22, email=username + '@yahoo.com' 

update AffDetail with (rowlock,updlock)
set PreferredLanguage='en-US'        

update MemberInfo with (rowlock,updlock) set Currency=22

update MemberDaily with (rowlock,updlock)
set Currency=22, AffCurrency=22,SysCurrency=22, AffExRate=1,SysExRate=1

update MemberDailyRemoved with (rowlock,updlock)
set Currency=22, AffCurrency=22,SysCurrency=22, AffExRate=1,SysExRate=1

update MemberDailyTransaction with (rowlock,updlock)
set Currency=22, AffCurrency=22,SysCurrency=22, AffExRate=1,SysExRate=1

update AffDaily with (rowlock,updlock)
set  AffCurrency=22,SysCurrency=22, AffExRate=1,SysExRate=1

update AffDailySummary with (rowlock,updlock)
set  AffCurrency=22,SysCurrency=22

update AffTrans with (rowlock,updlock)
set  AffCurrency=22,SysCurrency=22, SysExRate=1

update AffPayout with (rowlock,updlock)
set MemberCurrency=22, AffCurrency=22,SysCurrency=22, MemberExRate=1,SysExRate=1

update AffCommission with (rowlock,updlock)
set  AffCurrency=22,SysCurrency=22

-- Click Statistics.....
-- Bug Balance Brought Forward Adjustment function

