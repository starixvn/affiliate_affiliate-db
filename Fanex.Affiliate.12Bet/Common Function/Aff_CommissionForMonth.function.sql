USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_CommissionForMonth]    Script Date: 09/10/2013 05:39:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  User Defined Function dbo.Aff_CommissionForMonth    Script Date: 5/22/2013 8:34:10 AM ******/
  
  
ALTER FUNCTION [dbo].[Aff_CommissionForMonth]  
(  
 @AffID int,  
 @Month int,  
 @Year int  
)  
RETURNS @AffComm TABLE(SportID int, TotalQM int, commission decimal(9,8) , amount money,MemDeposit money,MemTurnOver money, MemWinlost money,NetWinlost money)      
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
  
Declare @FirstDay smalldatetime,@LastDay smalldatetime, @MinimumNegativeCommission float  
 , @HorseRacingID int,@SportsBookID int,@CasinoID int, @MinimumNegativeCasinoCommission float  
  
select @MinimumNegativeCommission = 0.1,  @MinimumNegativeCasinoCommission=0.05  
    
  
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'),@CasinoID=dbo.Aff_GetSportID('Casino')    
  
  
  
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))  

if(exists (select top(1) 1 from AffCommission(nolock) where winlostdate=@LastDay and AffID=@AffID))
begin
   insert into @AffComm(SportID, TotalQM, commission, amount,MemDeposit,MemTurnOver,MemWinlost,NetWinlost)   
select sportid,QualifiedMember,commission, AffWinlost,MemberDeposit,MemberTurnOver,MemberWinlost, -MemberSum
from  AffCommission (nolock)
 where winlostdate=@LastDay and AffID=@AffID

 RETURN
  
end
  
    



  
  
Declare @AffSummary Table  
(     
 AffID int,     
 Currency int,     
 GroupID int,  
 SportID int,  
 MemWinlost money,  
 MemBonus money,  
 MemAdjustment money,  
 MemPSP money,  
 Marketing money,  
 MemDeposit money,  
 MemTurnover money,  
 Commission decimal(9,8),  
 TotalQM int,    
 NetWinlost money,   
 BonusPercent float,  
 MarketingPercent float,  
 AdjustmentPercent float,  
 PSPPercent float,  
 OddsFeePercent float,  
 PlayTechRoyaltiesPercent float ,
IsPSPIncluded int -- flag to check PSP Fee is included or not for this product  
)  
  
INSERT INTO @AffSummary(AffID,Currency,GroupID,SportID,MemWinlost,MemBonus,MemAdjustment,MemPSP,Marketing,MemDeposit,MemTurnover,TotalQM,  
BonusPercent,  
AdjustmentPercent,  
MarketingPercent,PSPPercent,OddsFeePercent,PlayTechRoyaltiesPercent,IsPSPIncluded)  
  
Select t.AffID as AffID  
	,t.Currency as Currency  
	,t.GroupID as GroupID  
	,r.SportType as SportID  
	,sum(isnull(r.Winlost,0)) as MemWinlost  
	,sum(isnull(r.Bonus,0)) as MemBonus  
	,sum(isnull(r.Adjustment,0)) as MemAdjustment  
	,sum(isnull(r.PSP,0)) as MemPSP  
	,sum(isnull(r.Marketing,0)) as Marketing  
	,sum(isnull(r.Deposit,0)) as MemDeposit  
	,sum(isnull(r.Turnover,0)) as MemTurnover  
	,sum(case when r.TurnOver>=s.QMTurnOver and r.Deposit>=s.QMDeposit then 1 else 0 end) as TotalQM         
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Bonus',@LastDay) as BonusPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Adjustment',@LastDay) as AdjustmentPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Marketing',@LastDay) as MarketingPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'PSP',@LastDay) as PercentPSP  
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'Odds Fee',@LastDay) as OddsFeePercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,r.SportType,'PlayTech Royalties',@LastDay) as PlayTechRoyaltiesPercent    
	,0 as IsPSPIncluded 
FROM   
  (select ai.AffId,coalesce(gh.GroupID,ai.GroupID) as GroupID,Currency  
	 from AffInfo ai with (nolock)  
	left join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and MonthDate=@LastDay  
	 where ai.AffID=@AffID  
	
   ) t        
   left join   
   (  
  select IBCCustID,SportType,AffID  
	,sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost  
	  ,sum(isnull(Bonus,0) * isnull(AffExRate,1)) as Bonus  
	  ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment  
	  ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP  
	  ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing  
	  ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver  
	  ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit  
  from MemberDaily md  (nolock)   
  where WinlostDate between @FirstDay and @LastDay and md.AffID=@AffID  
  group by IBCCustID,SportType,AffID  
  
   ) r on r.AffID=t.AffID  
   left join SportType s (nolock) on s.SportID=r.SportType  
	  
group by t.AffID,t.GroupID, r.SportType,t.Currency  
  
 
-- Decide which SportID should include PSP

declare @PSP money, @maxwinlost money, @maxWinlostSportID int,@PSPPercent float


select @PSP=MemPSP,@PSPPercent=PSPPercent
from @AffSummary a
where a.SportID=@SportsBookID

select @maxwinlost=max(abs(MemWinlost)) from @AffSummary

select top(1) @maxWinlostSportID=sportid
from @AffSummary
where abs(MemWinlost)=@maxwinlost and SportID <> @SportsBookID

select @maxWinlostSportID=coalesce(@maxWinlostSportID,@SportsBookID), @PSP=coalesce(@PSP,0),@PSPPercent=coalesce(@PSPPercent,0)



update a

set a.IsPSPIncluded=1

from @AffSummary a

where a.sportid=@maxWinlostSportID



--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID  
  
update a  
set  a.NetWinlost=(-isnull(a.MemWinlost,0)   
	  - isnull(@PSP,0)* @PSPPercent * a.IsPSPIncluded
	 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)   
	),  
	  
  a.commission=isnull((select  top(1) Commission  
		from   
	   (  
		select isnull((select Commission  
			 from GroupSettingHistory(nolock)  
			 where GroupID=a.GroupID   
			 and SportType=a.SportID  
			 and MonthDate=@LastDay  
			 and floor(  
				abs( -isnull(a.MemWinlost,0)   
			  - isnull(@PSP,0)* @PSPPercent * a.IsPSPIncluded
				 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
				- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
				- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)                   
				)   
			   )  
			  between MinAmount and MaxAmount),0) as Commission  
		union all                               
		  select isnull((select top(1) Commission   
			   from GroupSettingHistory(nolock)  
			   where GroupID=a.GroupID   
			   and SportType=a.SportID   
			   and MonthDate=@LastDay  
			   and a.TotalQM between MinQM and MaxQM  
			   ),0)  
			 as Commission  
	   ) t    
	   order by t.Commission asc  
	 ),0)  
from @AffSummary a  
  
  
  
update a  
set a.Commission = (case when a.SportID=@CasinoID then @MinimumNegativeCasinoCommission else @MinimumNegativeCommission end)   
from @AffSummary a  
where a.NetWinlost < 0 and a.Commission = 0     
      and [dbo].[IsZeroCommissionGroup](a.GroupID,@LastDay)=0     
  	and a.SportID in (
		select distinct SportID from GroupSettingHistory (nolock) where GroupID=a.GroupID and DATEDIFF(m,MonthDate,@LastDay)=0
	  )    

  
insert into @AffComm(SportID, TotalQM, commission, amount,MemDeposit,MemTurnOver,MemWinlost,NetWinlost)   
select sportid,TotalQM,commission,sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)), SUM(ISNULL(a.MemDeposit,0)),SUM(ISNULL(a.MemTurnover,0)),SUM(ISNULL(a.MemWinlost,0)),SUM(ISNULL(a.NetWinlost,0))      
from  @AffSummary a  
group by sportid,TotalQM,commission  
  
RETURN  
	
END
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommissionForMonth] TO [vnteam] AS [dbo]