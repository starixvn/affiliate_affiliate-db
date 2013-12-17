  USE [Affiliate_12BET]

SET NOCOUNT ON
GO
if exists (select 1 from AffInfo with (nolock))
  begin
      truncate table AffInfo
  end
 

-- AffTrans
set identity_insert AffInfo on
GO
insert into AffInfo(
	  [AffID]
	  ,[UserName]
      ,[UserName2]      
	  ,[FirstName]
      ,[LastName]      
      ,[Status]
      ,[ApprovedDate]
      ,[IsClosed]
      ,[Currency]
      ,[RegisteredDate]
      ,[Email]
      ,[Password]
      ,[AffType]
      )
select
	c.CustId,
	c.Username,
	null as Username2,	
	c.FirstName,
	c.LastName,	
	af.status,
	af.ApprovalDate,
	ci.closed,
	c.currency,
	c.creatdate,
	c.email,
	c.userpwd,
	1 as AffType	
from bodb02.dbo.customer c with (nolock)
	inner join DB03.[12BetAffiliate].dbo.Affiliate_CustInfo af with (nolock) on c.custid = af.custid
	inner join bodb02.dbo.custinfo ci with (nolock) on c.custid = ci.custid	
where c.mrecommend = (Select top(1) CustID
                      From  bodb02.dbo.customer with (nolock)
                      where username='12BETAFF' 
                     )
      and c.roleid = 2
GO
set identity_insert AffInfo off
GO

--Assign Commission Group for Affiliate
declare @MaxGroupID int
select @MaxGroupID=max(groupid)
from CommGroup with (nolock)
select @MaxGroupID=coalesce(@MaxGroupID,102)
if @MaxGroupID<102
 select @MaxGroupID=102

declare @CommGroup table (apositiontaking float,groupid int IDENTITY(1,1),GroupName nvarchar(100), CreatedDate datetime,Creator int,IsDeleted bit,Description nvarchar(100))
 Declare @GroupSetting table(groupid int,sporttype int,tierID int,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))
 
 Insert Into @CommGroup(apositiontaking,GroupName,CreatedDate,Creator,IsDeleted,Description)
 Select distinct cs.apositiontaking,'CommGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) as GroupName,current_timestamp,148,0,'Group for converting data'
  from bodb02.dbo.custsetting cs with(nolock) 
      inner join AffInfo ai with (nolock) on ai.AffID=cs.CustID
WHERE sporttype = 1 
	AND bettype = 1 
	AND cs.apositiontaking<>0
	
	
declare @SportsBookID int,@HRSportID int

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HRSportID=dbo.Aff_GetSportID('Horse Racing')
	
	
Insert into @GroupSetting(groupid,sporttype,tierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
Select groupid + @MaxGroupID,@SportsBookID as SportType,1,0,100000000000000,0,1000000000,apositiontaking
from @CommGroup
union all
Select  groupid + @MaxGroupID,@HRSportID as SportType,1,0,100000000000000,0,1000000000,0
from @CommGroup

Delete GroupSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'CommGroup%')

Delete DeductionSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'CommGroup%')

Delete CommGroup
where GroupName like 'CommGroup%'

INSERT INTO [Affiliate_12BET].[dbo].[CommGroup]
           ([GroupID]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description])
Select  [GroupID] + @MaxGroupID
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
          
From @CommGroup

INSERT INTO [Affiliate_12BET].[dbo].[DeductionSetting]
           ([GroupID]
           ,[DeductionID]
          )

select  [GroupID] + @MaxGroupID,1 
From @CommGroup


INSERT INTO [Affiliate_12BET].[dbo].[GroupSetting]
           ([GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission])
Select [GroupID]
           ,[SportType]
           ,[TierID]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission]
From  @GroupSetting 

declare @NoCommGroupID int
select @NoCommGroupID=GroupID 
from CommGroup with (nolock)
where GroupName='NoCommission'


update ai
   set ai.GroupID=( case when cs.apositiontaking=0 then @NoCommGroupID
                          else (select groupid + @MaxGroupID
                                from @CommGroup
                                where GroupName='CommGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) )
                      end
                 )   
from AffInfo ai with (rowlock,updlock)
     inner join bodb02.dbo.custsetting cs with(nolock) on cs.custid= ai.AffID and cs.sporttype = 1 
	AND cs.bettype = 1 
	
where ai.Status='Approved'	
	