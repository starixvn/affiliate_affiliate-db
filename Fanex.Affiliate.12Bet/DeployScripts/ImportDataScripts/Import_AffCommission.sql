 --Check whether still have a pending request -->if yes--> raise an error
 
 /* Rejected tickets:
   still insert 1 row into AffTrans
   to AffCommission : AffWinlost will equal to 0
   each months will have commission groups equal to apositiontaking
   */
  
USE [Affiliate_12BET]

SET NOCOUNT ON
GO
/*if (exists (select 1 from DB03.[12BetAffiliate].dbo.Affiliate_Bettrans with (nolock) where Status='Pending'))
begin
	select 'Oops, still have some pending requests on old data. Cannot convert! Please check. '
	return
end*/
if (not exists (select 1 from AffTrans with (nolock)) )
begin
	truncate table AffTrans
end

if exists (select 1 from AffTrans with (nolock) where TransType=201)
  begin
      Delete AffTrans where TransType=201
  end
 
--AffCommision
if (exists (select 1 from AffCommission with (nolock)) )
begin
	truncate table AffCommission
end

--Create a commision group history and assign commission group history for affiliate from apositiontaking
 /*This commission group must be have IsDeleted=1  and GroupName='OldGroup[apositiontaking]', GroupID=103,104,.... */
 declare @MaxGroupID int
select @MaxGroupID=max(groupid)
from CommGroup with (nolock)
select @MaxGroupID=coalesce(@MaxGroupID,102)
if @MaxGroupID<102
 select @MaxGroupID=102
 
 declare @CommGroup table (apositiontaking float,groupid int IDENTITY(1,1),GroupName nvarchar(100), CreatedDate datetime,Creator int,IsDeleted bit,Description nvarchar(100))
 Declare @GroupSetting table(groupid int,sporttype int,tierID int,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))
 
 Insert Into @CommGroup(apositiontaking,GroupName,CreatedDate,Creator,IsDeleted,Description)
 Select distinct cs.apositiontaking,'OldGroup' + left(cast(floor(cs.apositiontaking * 100) as varchar(20)),2) as GroupName,current_timestamp,148,1,'Old Group for converting data'
  from bodb02.dbo.custsetting cs with(nolock) 
      inner join AffInfo ai with (nolock) on ai.AffID=cs.CustID
WHERE sporttype = 1 
	AND bettype = 1 
	
	
declare @SportsBookID int,@HRSportID int

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HRSportID=dbo.Aff_GetSportID('Horse Racing')
	
	
Insert into @GroupSetting(groupid,sporttype,tierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
Select groupid + @MaxGroupID,@SportsBookID as SportType,1,0,100000000000000,0,1000000000,apositiontaking
from @CommGroup
union all
Select groupid + @MaxGroupID,@HRSportID as SportType,1,0,100000000000000,0,1000000000,0
from @CommGroup

Delete GroupSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'OldGroup%')

Delete DeductionSetting
where GroupID in (Select  groupid  from CommGroup with (nolock) where GroupName like 'OldGroup%')

Delete CommGroup
where GroupName like 'OldGroup%'

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
                     
                      

INSERT INTO [Affiliate_12BET].[dbo].[AffCommission]
           ([RelNo]
           ,[AffID]
           ,[GroupID]
           ,[SportID]
           ,[WinlostDate]
           ,[QualifiedMember]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[AffWinlost]
           ,[Status]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit] 
           ,[Marketing])

  SELECT b.[TransID]
      ,b.[CustID]
      ,g.GroupID + @MaxGroupID
      ,@SportsBookID as SportID
      ,b.WinlostDate
      ,b.[QualifiedMember]
      ,cs.apositiontaking
      ,1 as HasBonus
      ,0 as HasAdjustment
      ,0 as HasMarketing
      ,0 as HasPSP
      ,isnull(b.Winlost,0)-isnull(b.Actual_Stake,0) as AffWinlost
      ,b.[Status]
      ,0 as MemberWinlost
      ,0 as MemberBonus
      ,0 as MemberAdjustment
      ,0 as MemberPSP
      ,0 as MemberSum
      ,0
      ,0
      ,0 as Marketing      
  FROM DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock)
       left join bodb02.dbo.custsetting cs with(nolock) on cs.CustID=b.custid and cs.sporttype = 1 AND cs.bettype = 1 
       inner join @CommGroup g on g.apositiontaking=cs.apositiontaking
  where b.bettype=105     
  
  update t
  set t.MemberWinlost =isnull(m.winlost,0),
       t.MemberBonus  =isnull(m.bonus,0),
       t.MemberAdjustment=isnull(m.Adjustment,0),
       t.MemberPSP=isnull(m.PSP,0),
       t.Marketing=isnull(m.Marketing,0),
       t.MemberTurnover=isnull(m.Turnover,0),   
       t.MemberDeposit=isnull(m.Deposit,0),   
       t.MemberSum=isnull(m.winlost,0) + isnull(m.bonus,0)
   from  AffCommission t with (rowlock,updlock)

         inner join 
              (
                select 
                       a.AffID as AffID,
                       a.WinlostDate as WinlostDate,
                       a.SportID as SportID,
                       sum(isnull(m1.winlost,0) * isnull(m1.AffExRate,0)) as winlost,
                       sum(isnull(m1.bonus,0)* isnull(m1.AffExRate,0)) as bonus,
                       sum(isnull(m1.Adjustment,0)* isnull(m1.AffExRate,0)) as Adjustment,
                       sum(isnull(m1.Turnover,0)* isnull(m1.AffExRate,0)) as Turnover,
                       sum(isnull(m1.Deposit,0)* isnull(m1.AffExRate,0)) as Deposit,
                       sum(isnull(m1.PSP,0)* isnull(m1.AffExRate,0)) as PSP,
                       sum(isnull(m1.Marketing,0)* isnull(m1.AffExRate,0)) as Marketing 
                 from MemberDaily m1 with (nolock) 
                    inner join AffCommission a with(nolock) on m1.AffID=a.AffID and  m1.SportType=a.SportID 
                  where datediff(m,m1.winlostdate,a.winlostdate)=0   
                  group by a.AffID,a.WinlostDate,a.SportID 
              ) m  on m.AffID=t.AffID and  m.SportID=t.SportID and m.WinlostDate=t.WinlostDate



--delete AffCommission where SportID=2
INSERT INTO [Affiliate_12BET].[dbo].[AffCommission]
           ([RelNo]
           ,[AffID]
           ,[GroupID]
           ,[SportID]
           ,[WinlostDate]
           ,[QualifiedMember]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[AffWinlost]
           ,[Status]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit]
           ,[Marketing])
 select    ac.[RefID]
           ,ac.[AffID]
           ,ac.[GroupID]
           ,@HRSportID as SportID
           ,ac.[WinlostDate]
           ,0 as [QualifiedMember]
           ,0 as [Commission]
           ,0 as [HasBonus]
           ,0 as [HasAdjustment]
           ,0 as [HasMarketing]
           ,0 as [HasPSP]
           ,0 as [AffWinlost]
           ,ac.[Status]
           ,isnull(t.winlost,0)
           ,isnull(t.bonus,0)
           ,isnull(t.Adjustment,0)
           ,isnull(t.PSP,0)
           ,isnull(t.winlost,0) + isnull(t.bonus,0) as MemberSum
           ,isnull(t.Turnover,0)
           ,isnull(t.Deposit,0)
           ,isnull(t.Marketing,0)   
from AffCommission ac with (nolock)
    inner join 
              (
                select 
                       a.AffID as AffID,
                       a.WinlostDate as WinlostDate,                       
                       sum(isnull(m1.winlost,0) * isnull(m1.AffExRate,0)) as winlost,
                       sum(isnull(m1.bonus,0)* isnull(m1.AffExRate,0)) as bonus,
                       sum(isnull(m1.Adjustment,0)* isnull(m1.AffExRate,0)) as Adjustment,
                       sum(isnull(m1.Turnover,0)* isnull(m1.AffExRate,0)) as Turnover,
                       sum(isnull(m1.Deposit,0)* isnull(m1.AffExRate,0)) as Deposit,
                       sum(isnull(m1.PSP,0)* isnull(m1.AffExRate,0)) as PSP,
                       sum(isnull(m1.Marketing,0)* isnull(m1.AffExRate,0)) as Marketing 
                 from MemberDaily m1 with (nolock) 
                    inner join AffCommission a with(nolock) on m1.AffID=a.AffID 
                  where datediff(m,m1.winlostdate,a.winlostdate)=0  and m1.SportType=@HRSportID
                  group by a.AffID,a.WinlostDate
              ) t  on t.AffID=ac.AffID and  t.WinlostDate=ac.WinlostDate
              
              
 -- AffPayout
set identity_insert AffTrans on
GO 
    INSERT INTO AffTrans
           ([TransID]
            ,[AffID]
           ,[TransDate]
           ,[CompletedDate]
           ,[Amount]
           ,[Status]
           ,[Description]
           ,[Creator]
           ,[Currency]
           ,[ActualRate]
           ,[TransType]
           ,[RefID]
           ,[AffExRate])
    SELECT 
       b.TransID
      ,ac.[AffID]
      ,ac.WinlostDate
      ,b.CompletedDate
      ,isnull(b.[Winlost],0)-isnull(b.[Actual_Stake],0) as Amount
      ,b.Status
      ,b.Description
      ,b.Creator
      ,ai.currency
      ,b.[IbcExRate_Mem]
      ,201 as TransType
      ,ac.RefID
      ,b.[IbcExRate_Aff] 
  FROM [Affiliate_12BET].[dbo].[AffCommission] ac with (nolock)
      inner join DB03.[12BetAffiliate].[dbo].[Affiliate_Bettrans] b with (nolock) on b.TransID=ac.RelNo
      left join AffInfo ai with (nolock) on ai.AffID=b.custid
GO
set identity_insert AffTrans off

update AffCommission with (rowlock,updLock)
set RelNo=RefID
where SportID=1



Select * from AffCommission with (nolock)
Select * from AffTrans  with (nolock) where TransType=201
Select * from CommGroup with (nolock)
Select * from GroupSetting with (nolock)
