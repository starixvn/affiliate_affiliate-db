ALTER Procedure [dbo].[Task_Aff_MonthlyTransfer] 
	@UserId int, 
    @Month int,   
    @Year int,
	@ErrCode int = 0 OUTPUT
      
AS  
/*  
Created: 20090812@DungTong  
Task : Monthly transfer for all Affiliate  
DB: Affiliate_Licensee  
Original:  
  
Revisions:      
    - 200900217@Dung:   
            + Use Tier Commission to calculate monthly earning for each Affiliate based on Aff's member winlosts.  
               To get commission value on what tier we do 3 phases:  
                 .Calculate Number Of Qualified members on this month (member that have the turn over for this month is greater than or equal to 100$)  
                 .Calculate winlost for each member on this month.  
                 .Calculate Deductions (based on deduction setting from affiliate's Group)  
                 .we have NetWinlost=WinLost-Deduction, TotalQMs  
                 .For each Affiliate we get commission value by this way:  
                      When TotalWinlost>0  
                           Commission=Commission by Net Winlost  
                      When TotalWinlost<=0                              
                        Commission=Min(Commission got by |NetWinlost| between MiAmount and MaxAmount, Commission got by TotalQMs between MinQM and MaxQMs)    
                 . Aff's Earning=NetWinlost * Commission  
            + We have only one place to get Winlost and Other Data from MemberDaily. and the day excute this task must greater than the last day of selected month                  
            + Qualifying member: Get Setting AFF_QMTurnOver from SystemSettings. Each member has  TurnOver>AFF_QMTurnOver --> qualified member  
            + All the transactions have the status=completed  
     - 20091203@Peter: Add Auto deduct transactions for Marketing fee  
                        Deduction=Affiliate Net Earning * 20%  
     - 20100115@Peter : Remove Auto deduct transactions for Marketing fee  
                        http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&sid=58e8c31d51dac7ddbef907a7a258c6cf&p=14064#p14064  
                          
     -20100211@Peter: #381 IRP - AffSite - Revise the calculations of the tier commission and PSP charge fee    
                      http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890        
                        
                     CNW=sum[(your total member's lost- your total member's won- bonus  - adjustment -  Marketing Fee)  * ExRate2].              
                     AComm= Min(commission get by |CNW|, commission get by TQM)  
                     MF= |Total Member's Lost-Total Member's Won| *  5%  
                     AE = CNW * Acomm  
                     AFE = AE -  PSP * 50%  
                       
                     Reupdate table AffDaily.   
                       
     -20100709@Peter:  
                    http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10  
                    Change the way to calculation:  
  
                    if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)  
                     and the minimum commission in this case is 10%  if the qualifying members <5.  
      -20100927@Peter:  
                 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236    
                 Change the way to calculation:  
                   PSP=deposit * depositpercent + withdrawal * withdrawalpercent  
                      For European Currencies: EURO,AUD,GBP, US$  
                          + depositpercent=0.06  
                          + withdrawalpercent=0.03  
                      For Asian Currencies:  
                          + depositpercent=0.02  
                          + withdrawalpercent=0.02  
                   PSP now follow tier commission  
                   New Fee:  Odds Management Fee = 17 % MemberWinlost  
                   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee  
                   From CNW => AComm  
                   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm         
         
	  - 20131029@Peter : Add more columns to DB https://redmine.nexcel.vn/issues/5280  
						- Calculate Affiliate BF in AffInfo table  
	  - 20131212@Johnny: Check permission before call monthly transfer.
  
Param's Explanation:  
• @Month: The month to transfer  
• @Year :  The year to transfer       
*/  
SET NOCOUNT ON  

EXEC [dbo].[Aff_Con_CheckPermission]  
	@custid=@UserId,  
	@funcname='[MonthlyTransfer]',
	@System = 'AFFILIATE',  
	@ErrCode=@ErrCode output

IF (@ErrCode <> 0)
	return
  
Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int, @MinimumNegativeCommission float  
  
select @MinimumNegativeCommission = 0.1  
  
  
  
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),  
    @TransType = 201  
  
if @LastDay > Current_TimeStamp  
BEGIN  
    SELECT 'The month is not completed yet. So you cannot transfer!' Result  
    SELECT @FirstDay as FirstDay,@LastDay as LastDay  
    RETURN  
END  
  
--Check group History data is inserted  
if(not exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay)   
   or not exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)  
 --  or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)  
   or  not exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)  
  )  
 BEGIN  
    SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month,@Year!' Result  
    SELECT @FirstDay as FirstDay,@LastDay as LastDay  
    RETURN  
 END  
IF EXISTS (select top(1) 1 from AffCommission with(nolock)  
            where WinlostDate=@LastDay)  
BEGIN  
    SELECT 'Please check the data. Transfers have been done for this month!' Result      
    SELECT @FirstDay as FirstDay,@LastDay as LastDay  
    RETURN  
END  
  
--Get all Affiliates that is approved and IsClosed=false  
declare @Status varchar(30)  
select @Status='Approved'  
  
  
--Check the currency is matched  
/*if(exists(select 1  
           from AffInfo ai with (nolock)  
                inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and MonthDate=@LastDay  
                inner join CommGroupHistory ch(nolock) on ch.groupid=gh.groupid  
           where ai.currency <> ch.currency and ai.status=@Status ) )   
begin  
    SELECT 'The currency of Affiliate and his group does not match. Please check!' Result      
    SELECT @FirstDay as FirstDay,@LastDay as LastDay  
    RETURN  
end*/  
  
--Create temp table to get summary data for each affiliate  
CREATE TABLE #MemberSummary  
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
 MemTurnoverNoDraw_aff money,  
  
)  
  
Insert into #MemberSummary( UserName ,  
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
     Select 'There was no data for selected month to transfer!' as Result  
     SELECT @FirstDay as FirstDay,@LastDay as LastDay    
     drop table #MemberSummary  
     return  
  end  
  
--Create temp table to get summary data for each affiliate  
CREATE TABLE #AffSummary  
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
  
INSERT INTO #AffSummary  
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
     inner join #MemberSummary r on r.AffID=ai.AffID  
   
where ai.status=@Status  
group by ai.AffID   
       ,ai.Currency  
       ,gh.GroupID  
       ,r.ProductID  
  
  
 delete from #AffSummary where ProductID is null  
  
 update a  
 set a.TotalActivePlayer=ISNULL(t.TotalActivePlayer,0)  
 from #AffSummary a with (nolock)  
 left join   
 (  
 select m.AffID,COUNT(distinct m.username) as TotalActivePlayer  
 from #MemberSummary m   
 where m.MemTurnover>0 --or m.MemDeposit>0  
 Group by m.AffID  
 ) t on a.AffID=t.AffID  
  
  
  
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
from #AffSummary a  
  
update a  
set a.Commission = @MinimumNegativeCommission  
from #AffSummary a  
where a.NetWinlost_aff < 0 and a.Commission = 0       
      and a.GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')  
       and a.ProductID in (  
        select distinct ProductID from GroupSettingHistory (nolock) where GroupID=a.GroupID and DATEDIFF(m,MonthDate,@LastDay)=0  
      )      
--Insert transaction to AffTrans and AffCommission  
declare @WinlostDate smalldatetime  
select @WinlostDate=current_timestamp  
  
declare  @SystemCurrency smallint  
set @SystemCurrency=dbo.Aff_GetSystemCurrencyID()  
  
  
  
begin transaction  
  
BEGIN TRY  
    declare @Temp table(RefID int, AffID int, ProductID tinyint)   
 -- Insert transaction to AffCommission  
    INSERT INTO [AffCommission]  
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
  
      
    output inserted.RefID,inserted.AffID,inserted.ProductID into @Temp   
    select AffID,GroupID,ProductID,@LastDay,Currency,@SystemCurrency, TotalQM,TotalActivePlayer,Commission   
           ,HasBonus,HasAdjustment,HasMarketing,HasPSP,HasOddsFee, @Status      
          ,(NetWinlost-Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)             
          ,MemWinlost  
          ,MemBonus  
          ,MemAdjustment  
          ,MemPSP  
          ,-NetWinlost  
          ,MemTurnover  
          ,MemDeposit      
          ,Marketing  
         , OddsFee  
         ,(NetWinlost_aff-Cast(a.HasBonus as int)* isnull(a.MemBonus_aff,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)             
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
  
    from #AffSummary a (nolock)      
      
    update d  
    set d.RelNo=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.RefID>0 )  
   from AffCommission d with (rowlock,updlock)         
   where d.WinlostDate=@LastDay  
  
   -- Insert to AffTrans  
   -- Peter@20131205 : Add deduction overal to monthly transfer transaction  
  
    insert into AffTrans(AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,AffCurrency,SysCurrency,SysExRate,TransType)  
    select a.AffID,@LastDay,@WinlostDate,sum((NetWinlost-Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1) )  * isnull(Commission,0)) - [dbo].[Aff_GetAffDeductionAll] (AffID,@LastDay)  ,@Status, 'Monthly Earning',  
         9999,a.Currency,@SystemCurrency,dbo.Aff_GetExchangeRate(a.Currency,@SystemCurrency,@LastDay),@TransType  
    from #AffSummary a (nolock)            
    group by a.AffID,a.Currency  
      
  
    update d  
    set d.RefID=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.RefID>0)  
   from AffTrans d with (rowlock,updlock)         
   where d.TransDate=@LastDay and d.TransType=@TransType   
          
         
   update ad   
     set   
        ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),  
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),  
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */  
                         
                       ) * isnull(a.commission,0),  
                         
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */  
                           ) * (1-isnull(a.commission,0))   
                  
      from AffDaily ad with (rowlock,updlock)    
      left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID       
   where datediff (mm,ad.Winlostdate, @FirstDay)=0    
     
   update ad   
     set /*ad.MemMarketing=Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0) ,  
         ad.MemOddsFee=Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0) ,         */  
        ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),  
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),  
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */  
                         
                       ) * isnull(a.commission,0),  
                         
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */  
                           ) * (1-isnull(a.commission,0)),   
  
        ad.AffWinlost_aff = -isnull(ad.MemWinlost_aff,0) *  isnull(a.commission,0),  
        ad.HouseWinlost_aff=-isnull(ad.MemWinlost_aff,0) * (1-isnull(a.commission,0)),  
        ad.AffNetWinlost_aff=( -isnull(ad.MemWinlost_aff,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */  
                         
                       ) * isnull(a.commission,0),  
                         
       ad.HouseNetWinlost_aff= (-isnull(ad.MemWinlost_aff,0)   
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)  
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1)   
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)                   
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)*isnull(a.BonusPercent,1)  
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */  
                           ) * (1-isnull(a.commission,0))   
                  
      from AffDailySummary ad with (rowlock,updlock)    
      left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID       
   where datediff (mm,ad.Winlostdate, @FirstDay)=0    
     
   -- Update BF for AffInfo  
   update ai  
   set ai.BF= dbo.[Aff_GetAffBalance](ad.AffID)  
   from AffInfo ai with (rowlock,updlock)  
   inner join #AffSummary ad (nolock) on ad.AffID=ai.AffID    
     
END TRY  
  
BEGIN CATCH  
    rollback transaction      
    drop table #AffSummary  
    drop table #MemberSummary  
    PRINT ERROR_MESSAGE()  
    RETURN  
END CATCH  
  
commit transaction  
  
  
declare @TaskID int,@LogID int , @RunDate datetime  
  
select @RunDate=getdate(), @Status='completed'  
  
select @TaskID= TaskID from TaskManager(nolock) where TaskName='Commission Monthly Transfer'  
exec [dbo].[Aff_TaskLogIns]  
    @TaskID,  
    @RunDate,  
    @Status,  
    @LogID OUTPUT  
drop table #AffSummary  
drop table #MemberSummary  
  
  
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MonthlyTransfer] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlyTransfer] TO [vnteam]