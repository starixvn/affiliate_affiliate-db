  
/****** Object:  User Defined Function dbo.Aff_CommissionForMonth    Script Date: 5/22/2013 8:34:10 AM ******/  
    
    
CREATE FUNCTION [dbo].[Aff_CommissionForMonth]    
(    
 @AffID int,    
 @Month int,    
 @Year int    
)    
RETURNS @AffComm TABLE(ProductID int, TotalQM int, commission decimal(9,8) , amount money,MemDeposit money,MemTurnOver money, MemWinlost money,NetWinlost money)        
AS   
/*  
 Task : Calculate monthy earning for affiliate  
 Author : Peter@20090909  
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
   
*/  
BEGIN   
    
  
Declare @FirstDay smalldatetime,@LastDay smalldatetime, @MinimumNegativeCommission float  
  
select @MinimumNegativeCommission = 0.1  
  
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))  
  
 Declare @GroupID int  
     
  Select @GroupID=GroupID  
   from AffGroupHistory (nolock)  
   Where AffID=@AffID and MonthDate=@LastDay  
     
  
Declare @AffSummary Table  
(  
 ProductID int,  
 MemWinlost money,  
 MemBonus money,   
 MemPSP money,      
    MemTurnover money,  
 Commission decimal(9,8),  
 TotalQM int,    
    NetWinlost money,  
    HasBonus bit,  
    HasMarketing bit,     
    HasPSP bit,  
    HasOddsFee bit,  
    BonusPercent float,  
    MarketingPercent float,     
    PSPPercent float,  
    OddsFeePercent float,  
    MemDeposit money  
   
)  
  
  
INSERT INTO @AffSummary(ProductID,MemWinlost,MemBonus,MemPSP,MemTurnover,  
          TotalQM,  
          HasBonus,  
          HasMarketing,           
          HasPSP,  
          HasOddsFee,  
          BonusPercent,            
          MarketingPercent,  
          PSPPercent,  
          OddsFeePercent,  
          MemDeposit)  
  
  
Select  r.ProductID as ProductID  
       ,sum(isnull(r.Winlost,0)) as MemWinlost  
       ,sum(isnull(r.Bonus,0)) as MemBonus         
       ,sum(isnull(r.PSP,0)) as MemPSP         
       ,sum(isnull(r.Turnover,0)) as MemTurnover  
       ,sum(case when r.TurnOver>=dbo.[Aff_GetQMTurnOver](@AffID,current_timestamp) then 1 else 0 end) as TotalQM        
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Bonus',@LastDay) as HasBonus  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Marketing',@LastDay) as HasMarketing  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'PSP',@LastDay) as HasPSP  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Odds Fee',@LastDay) as HasOddsFee  
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Bonus',@LastDay) as BonusPercent         
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Marketing',@LastDay) as MarketingPercent  
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'PSP',@LastDay) as PercentPSP  
  ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Odds Fee',@LastDay) as OddsFeePercent  
       ,sum(isnull(r.Deposit,0)) as MemDeposit  
FROM    
      (  
        select md.username,md.ProductID  
               ,sum(isnull(md.Winlost,0) * isnull(md.AffExRate,1)) as Winlost  
      ,sum(isnull(md.Bonus,0) * isnull(md.AffExRate,1)) as Bonus        
      ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP  
      ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing  
      ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver  
               ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit        
        from MemberDaily md  (nolock)         
          where AffID=@AffID and WinlostDate between @FirstDay and @LastDay   
              --  and (@ProductID=0 or md.ProductID=@ProductID)     
        group by  md.username,ProductID  
          
  
      ) r   
      --left join Product s (nolock) on s.ProductID=r.ProductID   
group by r.ProductID  
    
  
  
--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
  
update a  
set  a.NetWinlost=(-isnull(a.MemWinlost,0)   
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)   
                ),  
                  
     a.commission=isnull((select  top(1) Commission  
        from   
       (  
        select isnull((select Commission  
             from GroupSettingHistory(nolock)  
             where GroupID=@GroupID  
             and ProductID=a.ProductID  
             and MonthDate=@LastDay  
             and floor(  
                       abs(  
                 -isnull(a.MemWinlost,0)   
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                  -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)  
                   )  
               )   
              between MinAmount and MaxAmount),0) as Commission  
        union all                               
          select  isnull((select top(1) Commission   
                        from GroupSettingHistory(nolock)  
                                                      where GroupID=@GroupID   
               and ProductID=a.ProductID   
               and MonthDate=@LastDay  
               and a.TotalQM between MinQM and MaxQM  
                                                   ),0)  
            as Commission  
       ) t    
                            order by t.Commission asc  
                    ),0)  
  
from @AffSummary a  
  
  
if [dbo].[IsZeroCommissionGroup](@GroupID,@LastDay)<> 0   
begin  
update a  
set a.Commission = @MinimumNegativeCommission  
from @AffSummary a  
where a.NetWinlost < 0 and a.Commission = 0       
      and a.ProductID in (  
        select distinct ProductID from GroupSettingHistory (nolock) where GroupID=@GroupID and DATEDIFF(m,MonthDate,@LastDay)=0  
      )     
end       
    
insert into @AffComm(ProductID, TotalQM, commission, amount,MemDeposit,MemTurnOver,MemWinlost,NetWinlost)     
select ProductID,TotalQM,commission,sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)), SUM(ISNULL(a.MemDeposit,0)),SUM(ISNULL(a.MemTurnover,0)),SUM(ISNULL(a.MemWinlost,0)),SUM(ISNULL(a.NetWinlost,0))        
from  @AffSummary a    
group by ProductID,TotalQM,commission    
    
RETURN    
   
END  
  