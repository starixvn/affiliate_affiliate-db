ALTER FUNCTION [dbo].[Aff_CommissionForMonthAll]  
(  
 @Month int,  
 @Year int  
)  
RETURNS @AffComm TABLE([AffID] int 
           ,[GroupID]  int
           ,[ProductID]  tinyint
           ,[WinlostDate]  smalldatetime
           ,[AffCurrency]  smallint
           ,[SysCurrency]  smallint
           ,[QualifiedMember]  int
           ,[ActivePlayer]  int
           ,[Commission]  decimal(9,8)
           ,[HasBonus]  bit
           ,[HasAdjustment] bit  
           ,[HasMarketing]  bit
           ,[HasPSP]  bit
           ,[HasOddsFee] bit 
           ,[Status]  nvarchar(50)
           ,[AffWinlost]  money
           ,[MemberWinlost]  money
           ,[MemberBonus]  money
           ,[MemberAdjustment]  money
           ,[MemberPSP]  money
           ,[MemberSum]  money
           ,[MemberTurnover]  money
           ,[MemberDeposit]  money
           ,[Marketing]  money
           ,[MemOddsFee]  money
           ,[AffWinlost_aff]  money
           ,[MemberWinlost_aff]  money
            ,[MemberBonus_aff]  money
           ,[MemberAdjustment_aff]  money
           ,[MemberPSP_aff]  money
           ,[MemberSum_aff]  money
           ,[MemberTurnover_aff]  money
           ,[MemberDeposit_aff]  money
           ,[Marketing_aff]  money
           ,[MemOddsFee_aff]  money
           ,[MemberBetCount]  money
           ,[MemberTurnoverNoDraw] money 
           ,[MemberBetCountNoDraw]  money
           ,[MemberTurnoverNoDraw_aff]  money
           ,[MemberWithdrawal]  money
           ,[MemberWithdrawal_aff]  money
           ,[MemberTurnoverDraw]  money
           ,[MemberTurnoverDraw_aff] money)      
AS 
/*
	Task : Calculate monthy earning for affiliate
	Author : Peter@20090909

                                
	
*/
BEGIN	
  
Declare @FirstDay smalldatetime,@LastDay smalldatetime,@Today smalldatetime,@TransType int, @MinimumNegativeCommission float  
  
select @MinimumNegativeCommission = 0.1  
  
  
  
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),  
    @TransType = 201  

Select @Today = convert (varchar(12),current_timestamp)
if datediff(m,  @FirstDay, @Today)=0
    select @LastDay=@Today

  
declare @Status varchar(30)  
select @Status='Approved'  
  
  

--Create temp table to get summary data for each affiliate  
Declare @MemberSummary  TABLE 
(  
    UserName varchar(100),  
    AffID int,     
    ProductID int,  
  
    MemWinlost money,  
    MemBonus money,  
    MemAdjustment money,  
    MemPSP money,      
    MemDeposit money,  
    MemTurnover money,     
 MemWithdrawal money,   
 MemTurnoverDraw money,       
    MemTurnoverNoDraw money,  
    MemBetCount int,      
    MemBetCountNoDraw int,     
  
  
    MemWinlost_aff money,  
    MemBonus_aff money,  
    MemAdjustment_aff money,  
    MemPSP_aff money,      
    MemDeposit_aff money,  
    MemTurnover_aff money,  
 MemWithdrawal_aff money,  
 MemTurnoverDraw_aff money,   
 MemTurnoverNoDraw_aff money  
  
)  
  
Insert into @MemberSummary( UserName ,  
    AffID ,     
    ProductID,  
    MemWinlost,  
    MemBonus,  
    MemAdjustment ,  
    MemPSP,      
    MemDeposit,  
    MemTurnover,      
   MemWithdrawal,   
   MemTurnoverDraw,       
    MemTurnoverNoDraw,  
    MemBetCount,      
    MemBetCountNoDraw,     
  
    MemWinlost_aff,  
    MemBonus_aff,  
    MemAdjustment_aff,  
    MemPSP_aff,      
    MemDeposit_aff,  
    MemTurnover_aff,  
 MemWithdrawal_aff,  
 MemTurnoverDraw_aff,   
 MemTurnoverNoDraw_aff  
    )  
 select username,AffID,ProductID  
               ,sum(isnull(Winlost,0) * isnull(SysExRate,1)) as Winlost  
               ,sum(isnull(Bonus,0) * isnull(SysExRate,1)) as Bonus  
               ,sum(isnull(Adjustment,0) * isnull(SysExRate,1)) as Adjustment  
               ,sum(isnull(PSP,0) * isnull(SysExRate,1)) as PSP                
           ,sum(isnull(Deposit,0) * isnull(SysExRate,1)) as Deposit  
               ,sum(isnull(TurnOver,0) * isnull(SysExRate,1)) as TurnOver  
      ,sum(isnull(Withdrawal,0) * isnull(SysExRate,1)) as Withdrawal  
      ,sum(isnull(TurnOverDraw,0) * isnull(SysExRate,1)) as TurnOverDraw  
      ,sum(isnull(TurnOverNoDraw,0) * isnull(SysExRate,1)) as TurnOverNoDraw  
      ,sum(isnull(BetCount,0)) as BetCount  
      ,sum(isnull(BetCountNoDraw,0)) as BetCountNoDraw  
                 
                  
                ,sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost_aff  
               ,sum(isnull(Bonus,0) * isnull(AffExRate,1)) as Bonus_aff  
               ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment_aff  
               ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP_aff                
               ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit_aff  
               ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver_aff  
      ,sum(isnull(Withdrawal,0) * isnull(AffExRate,1)) as Withdrawal_aff  
      ,sum(isnull(TurnOverDraw,0) * isnull(AffExRate,1)) as TurnOverDraw_aff  
      ,sum(isnull(TurnOverNoDraw,0) * isnull(AffExRate,1)) as TurnOverNoDraw_aff  
                 
                  
 from MemberDaily md  (nolock)   
 where WinlostDate between @FirstDay and @LastDay   
 group by username,ProductID,AffID  
  
   
if(@@ROWCOUNT=0)  
  begin  
        
     return  
  end  
  
--Create temp table to get summary data for each affiliate  
declare  @AffSummary TABLE 
(  
   /* [No] int IDENTITY(1,1),*/  
    AffID int,  
    Currency smallint,     
    GroupID int,  
    ProductID int,  
  
    MemWinlost money,  
    MemBonus money,  
    MemAdjustment money,  
    MemPSP money,  
    Marketing money,  
    OddsFee money,  
    MemDeposit money,  
    MemTurnover money,  
    NetWinlost money,  
  
    MemWinlost_aff money,  
    MemBonus_aff money,  
    MemAdjustment_aff money,  
    MemPSP_aff money,  
    Marketing_aff money,  
    OddsFee_aff money,  
    MemDeposit_aff money,  
    MemTurnover_aff money,  
    NetWinlost_aff money,  
  
    Commission decimal(9,8),  
    TotalQM int,   
    TotalActivePlayer int,   
     
    HasBonus bit,  
    HasMarketing bit,  
    HasAdjustment bit,  
    HasPSP bit,  
    HasOddsFee bit,  
    BonusPercent float,  
    MarketingPercent float,  
    AdjustmentPercent float,  
    PSPPercent float,  
    OddsFeePercent float  
  
 ,[MemBetCount] int  
    ,[MemTurnoverNoDraw] money  
    ,[MemBetCountNoDraw] int  
    ,[MemTurnoverNoDraw_aff] money  
    ,[MemWithdrawal] money  
    ,[MemWithdrawal_aff] money  
    ,[MemTurnoverDraw] money  
    ,[MemTurnoverDraw_aff] money  
      
)  

if datediff(m,@FirstDay,current_timestamp)=0

BEGIN
  
INSERT INTO @AffSummary  
            (AffID,  
             Currency,  
             GroupID,  
             ProductID,  
             MemWinlost,  
             MemBonus,  
             MemAdjustment,  
             MemPSP,              
             MemDeposit,  
             MemTurnover,      
             MemWinlost_aff,  
             MemBonus_aff,  
             MemAdjustment_aff,  
             MemPSP_aff,               
             MemDeposit_aff,  
             MemTurnover_aff,  
             TotalQM,              
             HasBonus,  
             HasMarketing,  
             HasAdjustment,  
             HasPSP,  
             HasOddsFee,  
             BonusPercent,  
             AdjustmentPercent,  
             MarketingPercent,  
             PSPPercent,  
             OddsFeePercent  
    ,[MemBetCount]  
   ,[MemTurnoverNoDraw]  
   ,[MemBetCountNoDraw]  
   ,[MemTurnoverNoDraw_aff]  
   ,[MemWithdrawal]  
   ,[MemWithdrawal_aff]  
   ,[MemTurnoverDraw]  
   ,[MemTurnoverDraw_aff]  
    )  
  
Select ai.AffID as AffID  
       ,ai.Currency as Currency  
       ,ai.GroupID as GroupID  
       ,r.ProductID as ProductID  
       ,sum(isnull(r.MemWinlost,0)) as MemWinlost  
       ,sum(isnull(r.MemBonus,0)) as MemBonus  
       ,sum(isnull(r.MemAdjustment,0)) as MemAdjustment  
       ,sum(isnull(r.MemPSP,0)) as MemPSP         
       ,sum(isnull(r.MemDeposit,0)) as MemDeposit  
       ,sum(isnull(r.MemTurnover,0)) as MemTurnover  
  
       ,sum(isnull(r.MemWinlost_aff,0)) as MemWinlost_aff  
       ,sum(isnull(r.MemBonus_aff,0)) as MemBonus_aff  
       ,sum(isnull(r.MemAdjustment_aff,0)) as MemAdjustment_aff  
       ,sum(isnull(r.MemPSP_aff,0)) as MemPSP_aff         
       ,sum(isnull(r.MemDeposit_aff,0)) as MemDeposit_aff  
       ,sum(isnull(r.MemTurnover_aff,0)) as MemTurnover_aff  
             
       ,sum(case when isnull(r.MemTurnover,0)>=ch.QualifiedAmount then 1 else 0 end) as TotalQM        
         
       ,dbo.Aff_HasDeduction(ai.GroupID,r.ProductID,'Bonus',null) as HasBonus  
       ,dbo.Aff_HasDeduction(ai.GroupID,r.ProductID,'Marketing',null) as HasMarketing   
       ,dbo.Aff_HasDeduction(ai.GroupID,r.ProductID,'Adjustment',null) as HasAdjustment         
       ,dbo.Aff_HasDeduction(ai.GroupID,r.ProductID,'PSP',null) as HasPSP  
       ,dbo.Aff_HasDeduction(ai.GroupID,r.ProductID,'Odds Fee',null) as HasOddsFee  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Bonus',null) as BonusPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Adjustment',null) as AdjustmentPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Marketing',null) as MarketingPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'PSP',null) as PercentPSP  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Odds Fee',null) as OddsFeePercent  
  
    ,Sum(isnull([MemBetCount],0))  
       ,Sum(isnull([MemTurnoverNoDraw],0))  
       ,Sum(isnull([MemBetCountNoDraw],0))  
       ,Sum(isnull([MemTurnoverNoDraw_aff],0))  
       ,Sum(isnull([MemWithdrawal],0))  
       ,Sum(isnull([MemWithdrawal_aff],0))  
       ,Sum(isnull([MemTurnoverDraw],0))  
       ,Sum(isnull([MemTurnoverDraw_aff],0))  
      
FROM AffInfo ai with (nolock)       
      inner join CommGroup ch(nolock) on ch.groupid=ai.groupid
     inner join @MemberSummary r on r.AffID=ai.AffID  
   
where ai.status=@Status  
group by ai.AffID   
       ,ai.Currency  
       ,ai.GroupID  
       ,r.ProductID  
  
END
else if datediff(m,@FirstDay,current_timestamp)>0

BEGIN
  
INSERT INTO @AffSummary  
            (AffID,  
             Currency,  
             GroupID,  
             ProductID,  
             MemWinlost,  
             MemBonus,  
             MemAdjustment,  
             MemPSP,              
             MemDeposit,  
             MemTurnover,      
             MemWinlost_aff,  
             MemBonus_aff,  
             MemAdjustment_aff,  
             MemPSP_aff,               
             MemDeposit_aff,  
             MemTurnover_aff,  
             TotalQM,              
             HasBonus,  
             HasMarketing,  
             HasAdjustment,  
             HasPSP,  
             HasOddsFee,  
             BonusPercent,  
             AdjustmentPercent,  
             MarketingPercent,  
             PSPPercent,  
             OddsFeePercent  
    ,[MemBetCount]  
   ,[MemTurnoverNoDraw]  
   ,[MemBetCountNoDraw]  
   ,[MemTurnoverNoDraw_aff]  
   ,[MemWithdrawal]  
   ,[MemWithdrawal_aff]  
   ,[MemTurnoverDraw]  
   ,[MemTurnoverDraw_aff]  
    )  
  
Select ai.AffID as AffID  
       ,ai.Currency as Currency  
       ,gh.GroupID as GroupID  
       ,r.ProductID as ProductID  
       ,sum(isnull(r.MemWinlost,0)) as MemWinlost  
       ,sum(isnull(r.MemBonus,0)) as MemBonus  
       ,sum(isnull(r.MemAdjustment,0)) as MemAdjustment  
       ,sum(isnull(r.MemPSP,0)) as MemPSP         
       ,sum(isnull(r.MemDeposit,0)) as MemDeposit  
       ,sum(isnull(r.MemTurnover,0)) as MemTurnover  
  
       ,sum(isnull(r.MemWinlost_aff,0)) as MemWinlost_aff  
       ,sum(isnull(r.MemBonus_aff,0)) as MemBonus_aff  
       ,sum(isnull(r.MemAdjustment_aff,0)) as MemAdjustment_aff  
       ,sum(isnull(r.MemPSP_aff,0)) as MemPSP_aff         
       ,sum(isnull(r.MemDeposit_aff,0)) as MemDeposit_aff  
       ,sum(isnull(r.MemTurnover_aff,0)) as MemTurnover_aff  
             
       ,sum(case when isnull(r.MemTurnover,0)>=ch.QualifiedAmount then 1 else 0 end) as TotalQM        
         
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Bonus',@LastDay) as HasBonus  
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Marketing',@LastDay) as HasMarketing   
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Adjustment',@LastDay) as HasAdjustment         
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'PSP',@LastDay) as HasPSP  
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Odds Fee',@LastDay) as HasOddsFee  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Bonus',@LastDay) as BonusPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Adjustment',@LastDay) as AdjustmentPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Marketing',@LastDay) as MarketingPercent  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'PSP',@LastDay) as PercentPSP  
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Odds Fee',@LastDay) as OddsFeePercent  
  
    ,Sum(isnull([MemBetCount],0))  
       ,Sum(isnull([MemTurnoverNoDraw],0))  
       ,Sum(isnull([MemBetCountNoDraw],0))  
       ,Sum(isnull([MemTurnoverNoDraw_aff],0))  
       ,Sum(isnull([MemWithdrawal],0))  
       ,Sum(isnull([MemWithdrawal_aff],0))  
       ,Sum(isnull([MemTurnoverDraw],0))  
       ,Sum(isnull([MemTurnoverDraw_aff],0))  
      
FROM AffInfo ai with (nolock)  
     inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and gh.MonthDate=@LastDay      
     inner join CommGroupHistory ch(nolock) on ch.groupid=gh.groupid and ch.MonthDate=@LastDay   
     inner join @MemberSummary r on r.AffID=ai.AffID  
   
where ai.status=@Status  
group by ai.AffID   
       ,ai.Currency  
       ,gh.GroupID  
       ,r.ProductID  
  
END

  
 delete from @AffSummary where ProductID is null  
  
 update a  
 set a.TotalActivePlayer=ISNULL(t.TotalActivePlayer,0)  
 from @AffSummary a
 left join   
 (  
 select m.AffID,COUNT(distinct m.username) as TotalActivePlayer  
 from @MemberSummary m   
 where m.MemTurnover>0 --or m.MemDeposit>0  
 Group by m.AffID  
 ) t on a.AffID=t.AffID  
  
  

  
if datediff(m,@FirstDay,current_timestamp)>0

BEGIN

  
--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
  
update a  
set a.MemPSP= Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1),  
    a.MemPSP_aff= Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1),  
    a.Marketing=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1),  
    a.Marketing_aff=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1),  
    a.OddsFee=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) ,  
    a.OddsFee_aff=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) ,   
     
    a.NetWinlost_aff=(-isnull(a.MemWinlost_aff,0)   
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)  
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1)   
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)   
                ),  
    a.NetWinlost=(-isnull(a.MemWinlost,0)   
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)   
                ),  
                  
     a.commission=isnull((select  top(1) Commission  
                          from   
                            (  
                                select isnull((select Commission  
                                              from GroupSettingHistory(nolock)  
                                              where GroupID=a.GroupID   
                                                    and ProductID=a.ProductID  
                                                    and MonthDate=@LastDay  
                                                    and floor(  
                                                              abs(  
                                                               -isnull(a.MemWinlost_aff,0)   
                                                                 - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)  
                                                                -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1)   
                                                                 -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)   
                                                                )  
                                                            )   
                                                        between MinAmount and MaxAmount),0) as Commission  
                                union all                               
                                  select isnull((select top(1) Commission   
                                                      from GroupSettingHistory(nolock)  
                                                      where GroupID=a.GroupID   
                                                            and ProductID=a.ProductID   
                                                            and MonthDate=@LastDay  
                                                            and a.TotalQM between MinQM and MaxQM  
                                                   ),0)  
                                           as Commission  
                            ) t    
                            order by t.Commission asc  
                    ),0)  
from @AffSummary a  


  
update a  
set a.Commission = @MinimumNegativeCommission  
from @AffSummary a  
where a.NetWinlost_aff < 0 and a.Commission = 0  
      and [dbo].[IsZeroCommissionGroup](a.GroupID,@LastDay)<> 0           
       and a.ProductID in (  
        select distinct ProductID from GroupSettingHistory (nolock) where GroupID=a.GroupID and DATEDIFF(m,MonthDate,@LastDay)=0  
      )  

END

  
if datediff(m,@FirstDay,current_timestamp)=0

BEGIN

  
--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
  
update a  
set a.MemPSP= Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1),  
    a.MemPSP_aff= Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1),  
    a.Marketing=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1),  
    a.Marketing_aff=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1),  
    a.OddsFee=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) ,  
    a.OddsFee_aff=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) ,   
     
   a.NetWinlost_aff=(-isnull(a.MemWinlost_aff,0) 
                  - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1) 
                ),  
   

 a.NetWinlost=(-isnull(a.MemWinlost,0) 
                  - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
                )
   ,  
                  
     a.commission=isnull((select  top(1) Commission  
                          from   
                            (  
                                select isnull((select Commission  
                                              from GroupSetting(nolock)  
                                              where GroupID=a.GroupID   
                                                    and ProductID=a.ProductID                                                      
                                                    and floor(  
                                                              abs(  
                                                               -isnull(a.MemWinlost_aff,0)   
                                                                 - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)  
                                                                -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1)   
                                                                 -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)   
                                                                )  
                                                            )   
                                                        between MinAmount and MaxAmount),0) as Commission  
                                union all                               
                                  select isnull((select top(1) Commission   
                                                      from GroupSetting (nolock)  
                                                      where GroupID=a.GroupID   
                                                            and ProductID=a.ProductID                                                               
                                                            and a.TotalQM between MinQM and MaxQM  
                                                   ),0)  
                                           as Commission  
                            ) t    
                            order by t.Commission asc  
                    ),0)  
from @AffSummary a  

  

update a  
set a.Commission = @MinimumNegativeCommission  
from @AffSummary a  
where a.NetWinlost_aff < 0 and a.Commission = 0  
      and [dbo].[IsZeroCommissionGroup](a.GroupID,@LastDay)<> 0           
       and a.ProductID in (  
        select distinct ProductID from GroupSetting (nolock) where GroupID=a.GroupID 
      )  

END

    
--Insert transaction to AffTrans and AffCommission  
declare @WinlostDate smalldatetime  
select @WinlostDate=current_timestamp  
  
declare  @SystemCurrency smallint  
set @SystemCurrency=dbo.Aff_GetSystemCurrencyID()  
  
  

    INSERT INTO @AffComm
           ([AffID]  
           ,[GroupID]  
           ,[ProductID]  
           ,[WinlostDate]  
           ,[AffCurrency]  
           ,[SysCurrency]  
           ,[QualifiedMember]  
           ,[ActivePlayer]  
           ,[Commission]  
           ,[HasBonus]  
           ,[HasAdjustment]  
           ,[HasMarketing]  
           ,[HasPSP]  
           ,[HasOddsFee]  
           ,[Status]  
           ,[AffWinlost]  
           ,[MemberWinlost]  
           ,[MemberBonus]  
           ,[MemberAdjustment]  
           ,[MemberPSP]  
           ,[MemberSum]  
           ,[MemberTurnover]  
           ,[MemberDeposit]  
           ,[Marketing]  
           ,[MemOddsFee]  
           ,[AffWinlost_aff]  
           ,[MemberWinlost_aff]  
            ,[MemberBonus_aff]  
           ,[MemberAdjustment_aff]  
           ,[MemberPSP_aff]  
           ,[MemberSum_aff]  
           ,[MemberTurnover_aff]  
           ,[MemberDeposit_aff]  
           ,[Marketing_aff]  
           ,[MemOddsFee_aff]  
     ,[MemberBetCount]  
           ,[MemberTurnoverNoDraw]  
           ,[MemberBetCountNoDraw]  
           ,[MemberTurnoverNoDraw_aff]  
           ,[MemberWithdrawal]  
           ,[MemberWithdrawal_aff]  
           ,[MemberTurnoverDraw]  
           ,[MemberTurnoverDraw_aff])  
  
      
    
    select AffID,GroupID,ProductID,@LastDay,Currency,@SystemCurrency, TotalQM,TotalActivePlayer,Commission   
           ,HasBonus,HasAdjustment,HasMarketing,HasPSP,HasOddsFee, @Status      
          ,(NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)

          
          ,MemWinlost  
          ,MemBonus  
          ,MemAdjustment  
          ,MemPSP  
          ,-NetWinlost  
          ,MemTurnover  
          ,MemDeposit      
          ,Marketing  
         , OddsFee  
         ,(NetWinlost_aff-isnull(a.MemBonus_aff,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)
          ,MemWinlost_aff  
          ,MemBonus_aff  
          ,MemAdjustment_aff  
          ,MemPSP_aff  
          ,-NetWinlost_aff  
          ,MemTurnover_aff  
          ,MemDeposit_aff      
          ,Marketing_Aff  
          ,OddsFee_Aff  
    ,[MemBetCount]  
    ,[MemTurnoverNoDraw]  
    ,[MemBetCountNoDraw]  
    ,[MemTurnoverNoDraw_aff]  
    ,[MemWithdrawal]  
    ,[MemWithdrawal_aff]  
    ,[MemTurnoverDraw]  
    ,[MemTurnoverDraw_aff]  
  
    from @AffSummary a  
 

  
  
RETURN  
	
END
