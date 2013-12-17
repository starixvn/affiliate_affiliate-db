Update MemberInfo with (rowlock,updlock)
set email='test@yahoo.com',firstname='test',lastname='test',username=replace(username,'12bet$','')

truncate table BankTrans

update EmailHistory with (rowlock,updlock)
set ip='127.0.0.1',email='test@yahoo.com',content='test test',sender='customer'

truncate table News
truncate table On_User

update adminNotes with (rowlock,updlock)

set Note='Test'

update ClickStatistics_bk with (rowlock,updlock) set IP='127.0.0.1'

truncate table ClickStatistics_bk

truncate table Deposit_Customer

truncate table Deposit_depositinfo

truncate table Deposit_withdrawalinfo

update UserLog with (rowlock,updlock)  set IP='127.0.0.1'

update UserLog_RunSP with (rowlock,updlock)  set IP='127.0.0.1'
--bodb_Maintenance
truncate table Odds_UserLog

--Deposit_DB

update dbo.Deposit_Customer with (rowlock,updlock) 
set firstname='test',lastname='test',address='test',city='test',state='test', email='test@yahoo.com'
    ,LastLoginIP='127.0.0.1'