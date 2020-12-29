/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20201201@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: User permission control - Migrate data
*/

use Affiliate_12BET
go

declare @FunctionPermission table (FuncName varchar(100), Management tinyint, Settlement tinyint, Risk tinyint, Marketing tinyint, AsstMarketing tinyint, ITUser tinyint)
insert into @FunctionPermission (FuncName, Management, Settlement, Risk, Marketing, AsstMarketing, ITUser)
values
('[SecurityQA]'			, 3, 0, 0, 0, 0, 1)
,('[AffPhone]'			, 3, 0, 0, 1, 0, 1)
,('[AffEmail]'			, 3, 0, 0, 1, 0, 1)
,('[AffPaymentInfo]'	, 3, 0, 1, 0, 0, 1)
,('[AffWebURL]'			, 3, 0, 0, 1, 1, 1)
,('[AssignCommGroup]'	, 3, 0, 1, 1, 0, 1)
,('[AffMarket]'			, 3, 0, 1, 1, 0, 1)
,('[AffTurnover]'		, 3, 0, 1, 0, 0, 1)
,('[Note]'				, 3, 1, 1, 1, 1, 1)
,('[AffAdjustment]'		, 3, 3, 1, 0, 0, 1)
,('[AffAccountStatus]'	, 3, 1, 1, 1, 0, 1)
,('[AffReport]'			, 3, 0, 1, 1, 0, 1)
,('[ExportExcel]'		, 3, 0, 1, 0, 0, 1)
,('[AffPlayerDetail]'	, 3, 0, 1, 0, 0, 1)
,('[AffMemberName]'		, 3, 0, 1, 0, 0, 1)
,('[AffPassword]'		, 3, 0, 0, 0, 0, 1)
,('[Affiliate]'			, 3, 0, 1, 0, 0, 1)
,('[Payment]'			, 3, 3, 1, 1, 0, 1)
,('[CommissionGroup]'	, 3, 0, 1, 0, 0, 1)
,('[AffMember]'			, 3, 0, 0, 0, 0, 1)
,('[AffMemberDetail]'	, 3, 0, 0, 0, 0, 1)
,('[ActiveMembers]'		, 3, 0, 0, 0, 0, 1)
,('[AffEx.Rate]'		, 3, 1, 1, 0, 0, 1)
,('[HotNews]'			, 3, 1, 1, 3, 1, 1)
,('[Domain]'			, 3, 0, 0, 0, 0, 1)
,('[UserControl]'		, 3, 0, 0, 0, 0, 1)
,('[Home]'				, 3, 3, 3, 3, 3, 1)
,('[Customer]'			, 3, 3, 3, 3, 3, 1)
,('[Media]'				, 3, 0, 1, 3, 3, 1)

;with cte_permission as (
	select r.RoleId, f.FuncId, t.Policy
	from @FunctionPermission fp
		inner join dbo.Functions f with (nolock) on fp.FuncName = f.FuncName
		cross apply (
			select 'Management' as RoleName, fp.Management as Policy
			union all select 'Exe. Settlement', fp.Settlement
			union all select 'Exe. Risk Team', fp.Risk
			union all select 'Exe. Marketing', fp.Marketing
			union all select 'Asst. Marketing', fp.AsstMarketing
			union all select 'IT User', fp.ITUser
		) t
		inner join dbo.Roles r with (nolock) on t.RoleName = r.RoleName
)
update r
set r.Policy = p.Policy
from dbo.RoleFunction r with (rowlock)
	inner join cte_permission p on r.RoleId = p.RoleId and r.FuncId = p.FuncId

declare @starixId int = 10000000

declare @user table (Old_CustId int, New_CustId int, RoleId smallint, UserName varchar(50), FirstName nvarchar(50), LastName nvarchar(50), RoleName varchar(100))
insert into @user
select 'AAabhi','Abhinav','Marketing','exe. Marketing' union all
select 'AAAnnie','Nguyen Thi','Marketing','asst. marketing' union all
select 'AAfraud','Risk','Fraud Dept','exe. Risk team' union all
select 'AAfraud2','Risk Depart','Fraud Dept','exe. Risk team' union all
select 'AAisaac','Isaac','Marketing','exe. Marketing' union all
select 'AAjames','James','Marketing','asst. marketing' union all
select 'AAjeff','jeff','Super admin','Management' union all
select 'AAjimts','jim','Marketing','exe. Marketing' union all
select 'AAkelly','Tseng','Marketing','exe. Marketing' union all
select 'AAkenny','Kenny','Marketing','exe. Marketing' union all
select 'AAmaggie','Maggie','Super admin','Management' union all
select 'AAMelvyn','Melvyn','Marketing','exe. Marketing' union all
select 'AAnicole','Nicole','Marketing','asst. marketing' union all
select 'AApatricklee','Lee','Finance','exe. Settlement' union all
select 'AApete','pete','Marketing','exe. Marketing' union all
select 'AAreginald','Reginald','None','exe. Settlement' union all
select 'AAseo','Ton','Marketing','asst. marketing' union all
select 'AAsteve','Steve','Super admin','Management' union all
select 'Test','testtest','Marketing','exe. Marketing'

insert into dbo.Users (UserName, RoleId, FirstName, LastName, UserPwd)
select u.UserName, r.RoleId, u.FirstName, u.LastName, ISNULL(au.UserPwd, '')
from @user u
	inner join dbo.Roles r with (nolock) on r.RoleName = u.RoleName
	left join dbo.Affiliate_User au with (nolock) on u.UserName = au.Username

update t
set t.Old_CustId = au.custid, t.New_CustId = u.CustId, t.RoleId = r.RoleId
from @user t
	inner join dbo.Users u with (nolock) on t.UserName = u.UserName
	inner join dbo.Roles r with (nolock) on t.RoleName = r.RoleName
	left join dbo.Affiliate_User au with (nolock) on t.UserName = au.Username

insert into dbo.UserFunction (CustId, FuncId, Policy)
select u.New_CustId, rf.FuncId, rf.Policy
from @user u
	INNER JOIN dbo.RoleFunction rf with (nolock) on u.RoleId = rf.RoleId

INSERT INTO dbo.UserMarket (CustId, MarketId)
SELECT u.New_CustId, rm.MarketId
FROM @user u
	INNER JOIN dbo.RoleMarket rm with (nolock) on u.RoleId = rm.RoleId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.[12BetDomain] d
	left join @user t on d.Creator = t.Old_CustId

update d with (rowlock)
set d.AdminID = isnull(t.New_CustId, @starixId)
from dbo.AdminFavorite d
	left join @user t on d.AdminID = t.Old_CustId

update d with (rowlock)
set d.UpdatedBy = isnull(t.New_CustId, @starixId)
from dbo.AdminNotes d
	left join @user t on d.UpdatedBy = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.AffDomain d
	left join @user t on d.Creator = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.AffDomainControl d
	left join @user t on d.Creator = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.AffTrans d
	left join @user t on d.Creator = t.Old_CustId
where d.TransType = 202

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.AffTrans d
	left join @user t on d.Creator = t.Old_CustId
where d.TransType = 203

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.Banners d
	left join @user t on d.Creator = t.Old_CustId

update d with (rowlock)
set d.UpdatedBy = isnull(t.New_CustId, @starixId)
from dbo.Banners d
	left join @user t on d.UpdatedBy = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.CommGroup d
	left join @user t on d.Creator = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.EmailHistory d
	left join @user t on d.Creator = t.Old_CustId
where d.Creator <> -1

update d with (rowlock)
set d.RemovedBy = isnull(t.New_CustId, @starixId)
from dbo.MemberRemoval d
	left join @user t on d.RemovedBy = t.Old_CustId

update d with (rowlock)
set d.Creator = isnull(t.New_CustId, @starixId)
from dbo.News d
	left join @user t on d.Creator = t.Old_CustId