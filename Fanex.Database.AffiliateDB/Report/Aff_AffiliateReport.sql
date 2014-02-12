ALTER Procedure [dbo].[Aff_AffiliateReport]  
 @PreferredLanguage varchar(11) = null,  
 @Fromdate datetime,  
 @Todate datetime,  
 @Currency smallint = 0,  
 @IsGetAll bit,  
 @AffType tinyint = 0  
AS  
/*  
Created: @VinhTrinh  
Task : Get report by date for each affiliate.  
DB: DB052.Affiliate_ZZun  
Original: [Aff_AffiliateReport]  
Revisions:  
      
Param's Explanation:  
 • @Fromdate Time search From  
 • @Todate Time search To,  
 • @IsGetAll if getall = 1 => get data in all date,  
*/  
Set Nocount On  
Select @FromDate = dbo.Date_Only(@FromDate), @ToDate = dbo.Date_Only(@ToDate)  
Declare @CurrDate datetime, @TmpToDate datetime  
  
if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN  
  
select @CurrDate =  dbo.Aff_GetEndDate(current_timestamp),  
  @Fromdate = dbo.Aff_GetStartDate(@Fromdate),  
  @Todate = dbo.Aff_GetEndDate(@Todate)  
   
if @IsGetAll = 1  
Begin  
 select @FromDate = min(WinlostDate) from AffDailySummary with (nolock)  
 select @ToDate = @CurrDate  
   
 select @TmpToDate = @CurrDate--To date for new way calculate winlost  
End  
Else  
Begin  
 select @TmpToDate = case when @ToDate >= @CurrDate then @CurrDate else @ToDate end   
End  
  
 --select @FromDate as FromDate, @ToDate as ToDate , @TmpFromDate as TmpFromDate, @TmpToDate as TmpToDate, @TmpOldWayDate as TmpOldWayDate  
   
Create table #AffTemp(AffID int PRIMARY KEY,UserName varchar(100),Currency varchar(10),Prefix varchar(10),  
Deposit money,  
 Withdrawal money,  
 Turnover money,  
 Winlost money,  
 Bonus money,  
 PSP money,  
 Adjustment money,  
 AffAdjustment money,  
 AffWithdrawal money,  
 AffBF money  
)  
  
insert into #AffTemp(AffID ,UserName,Currency,Prefix)  
Select ai.AffId, ai.Username, e.Code, e.Prefix  
From AffDetail ad with (nolock)  
 inner join AffInfo ai with(nolock) on ad.AffId = ai.AffId    
 inner join Exchange e with(nolock) on ai.Currency = e.ExchangeID  
where (@AffType=0 or ai.AffType = @AffType)  
  and (@PreferredLanguage is null or @PreferredLanguage= PreferredLanguage)  
  and (@Currency=0 or @Currency= ai.Currency)  
/*  
update at  
set at.Deposit=Sum(b.Deposit),  
    at.Withdrawal=Sum(b.Withdrawal),  
    at.Turnover=Sum(b.Turnover)   
from #AffTemp at  
    inner join AffDailySummary ad with(nolock) on ad.AffID=at.AffID  
Where ad.WinlostDate Between @FromDate and @TmpToDate  
group by ad.affid*/  
  
select t.AffId,  
 at.Username,  
 at.Currency,  
 at.Prefix,  
 Sum(t.Deposit) as Deposit,  
 Sum(t.Withdrawal) as Withdrawal,  
 Sum(t.Turnover) as Turnover,  
 Sum(t.Winlost) as Winlost,  
 Sum(t.Bonus) as Bonus,  
 Sum(t.PSP) as PSP,  
 Sum(t.Adjustment) as Adjustment,  
 Sum(t.AffAdjustment) as AffAdjustment,  
 Sum(t.AffWithdrawal) as AffWithdrawal,  
 Sum(t.AffBF) as AffBF,  
 aft.Name as AffTypeName  
From   
 (  
   
  Select a.AffId,--Calculate winlost member below Aff in MemberDaily  
   Sum(MemDeposit_aff) as Deposit,  
   Sum(MemWithdrawal_aff) as Withdrawal,  
   Sum(MemTurnover_aff) as Turnover,  
   Sum(MemWinlost_aff) as Winlost,  
   Sum(MemBonus_aff) as Bonus,  
   Sum(MemPSP_aff) as PSP,  
   Sum(MemAdjustment_aff) as Adjustment,  
   0 as AffAdjustment,  
   0 as AffWithdrawal,  
   sum(AffNetWinlost_aff) as AffBF     
  From AffDailySummary ad with(nolock)  
             inner join #AffTemp a on  a.AffID=ad.AffID             
  Where WinlostDate Between @FromDate and @TmpToDate  
  Group by a.AffID    
  Union All    
  select a.AffId,--Get Aff Adjusment and Aff Widthrawal  
   0 as Deposit,  
   0 as Withdrawal,  
   0 as Turnover,  
   0 as Winlost,  
   0 as Bonus,  
   0 as PSP,  
   0 as Adjustment,  
   Sum(case when Transtype = 203 then Amount else 0 end) as AffAdjustment,  
   Sum(case when Transtype = 202 then abs(Amount)  else 0 end) as AffWithdrawal,  
   0 as AffBF  
  From AffTrans a with (nolock)  
    inner join #AffTemp a1 on  a1.AffID=a.AffID  
  where (@IsGetAll = 1 or TransDate between @FromDate and @ToDate)  
   and Transtype in (202, 203)  
   and status in ('Pending', 'Approved', 'Completed')  
  Group by a.AffId  
 ) t  
inner join #AffTemp at on at.affid=t.affid  
inner join AffInfo ai with(nolock) on at.AffID = ai.AffID  
left join AffType aft with(nolock) on ai.AffType = aft.TypeID  
  
Group by t.AffId, at.Username, at.Currency, at.Prefix,aft.Name  
Order by t.AffId  
  
drop table #AffTemp  
  

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateReport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReport] TO [VNTeam] 
GO