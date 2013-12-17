/****** Object:  User Defined Function dbo.Aff_CommissionForCurrentMonth    Script Date: 5/22/2013 8:34:10 AM ******/  
CREATE FUNCTION [dbo].[Aff_CommissionForCurrentMonth]    
(    
 @AffID int    
)    
RETURNS @AffComm TABLE(ProductID int, TotalQM int, commission decimal(9,8) , amount money,MemDeposit money,MemTurnOver money, MemWinlost money,NetWinlost money)      
AS     
/*  
   - 20120514@Peter : Apply new formula according to Joycee's request  
  
    IF Winloss in SPORTSBOOK > winloss in Casino then   
       
       CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe  
     Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee  
    else  
       CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee  
       Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee  
  
*/  
BEGIN    
    
    
 --SET NOCOUNT ON  
 Declare @FirstDay smalldatetime,@LastDay smalldatetime,@Today smalldatetime, @MinimumNegativeCommission float  
    
select @MinimumNegativeCommission = 0.1  
  
  
Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @Today = convert (varchar(12),current_timestamp)  
select @LastDay=@Today  
  
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
  
Declare @GroupID int  
     
Select @GroupID=GroupID  
from AffInfo (nolock)  
Where AffID=@AffID  
  
  
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
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Bonus',null) as HasBonus  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Marketing',null) as HasMarketing  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'PSP',null) as HasPSP  
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Odds Fee',null) as HasOddsFee  
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Bonus',null) as BonusPercent         
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Marketing',null) as MarketingPercent  
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'PSP',null) as PercentPSP  
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Odds Fee',null) as OddsFeePercent  
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
               -- and (@ProductID=0 or md.ProductID=@ProductID)     
        group by  md.username,ProductID  
          
  
      ) r   
      --left join Product s (nolock) on s.ProductID=r.ProductID   
group by r.ProductID  
   
  
  
--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID  
  
update a  
set   a.NetWinlost=(-isnull(a.MemWinlost,0)   
                  - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)  
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1)   
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)   
                ),  
      a.commission=isnull((select  top(1) Commission  
        from   
       (  
        select isnull((select Commission  
             from GroupSetting(nolock)  
             where GroupID=@GroupID   
             and ProductID=a.ProductID               
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
          select isnull((select top(1) Commission   
                        from GroupSetting(nolock)  
                                                      where GroupID=@GroupID  
               and ProductID=a.ProductID                  
               and a.TotalQM between MinQM and MaxQM  
                                                   ),0)  
             as Commission  
       ) t    
                            order by t.Commission asc  
                    ),0)  
from @AffSummary a  
  
if [dbo].[IsZeroCommissionGroup](@GroupID,@Today)<> 0   
begin  
	update a  
	set a.Commission = @MinimumNegativeCommission  
	from @AffSummary a  
	where a.NetWinlost < 0 and a.Commission = 0       
		  and a.ProductID in (  
			select distinct ProductID from GroupSetting (nolock) where GroupID=@GroupID   
		  )     
end     
    
  
insert into @AffComm(ProductID, TotalQM, commission, amount,MemDeposit,MemTurnOver,MemWinlost,NetWinlost)    
select ProductID,TotalQM,commission,sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)), SUM(ISNULL(a.MemDeposit,0)),SUM(ISNULL(a.MemTurnover,0)),SUM(ISNULL(a.MemWinlost,0)),SUM(ISNULL(a.NetWinlost,0))      
from  @AffSummary a    
group by ProductID,TotalQM,commission    
    
    
RETURN    
      
END  
  