/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20200925@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: New permission: Turnover
*/

use Affiliate_12BET
go

declare @FuncId int, @Creator int = 862400, @currentDate datetime = getdate()

insert into dbo.AffFunctionInfo (FuncName,FuncDesc,FuncRender,CreateDate,ModifyDate,DisplayOrder,Creator,ParentID,Filenames,System)
values ('[Turnover]','Turnover',3,@currentDate,@currentDate,1,@Creator,0,'','AFFILIATE')
select @FuncId = SCOPE_IDENTITY()

update dbo.AffFunctionInfo with (rowlock)
set ParentId = @FuncId
where FuncId = @FuncId

insert into dbo.AffGroupPolicy (GroupId,FuncId,Policy,CreateDate,ModifyDate,Creator)
select GroupId,@FuncId,0,@currentDate,@currentDate,@Creator
from dbo.AffGroupInfo with (nolock)

insert into dbo.AffMemberPolicy (CustId,FuncId,Policy,CreateDate,ModifyDate,Creator)
select CustId,@FuncId,0,@currentDate,@currentDate,@Creator
from dbo.Affiliate_User with (nolock)