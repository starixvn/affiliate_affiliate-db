USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CalMonthlyEarning]    Script Date: 05/14/2013 01:40:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarning    Script Date: 1/18/2013 6:02:36 AM ******/
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarning    Script Date: 1/16/2013 5:19:01 PM ******/

ALTER PROCEDURE [dbo].[Aff_CalMonthlyEarning] (
@AffID int,
@Month int,
@Year int,
@QualifiedMembers int = 0 output,
@CAQualifiedMembers int = 0 output,
@Amount money OUTPUT, -- Amount with Marketing Fee included for Sportbook
@CAAmount  money = 0 OUTPUT, -- Amount with Marketing Fee included for Casino
@SPCommission float OUTPUT,
@HRCommission float OUTPUT,
@CACommission float = 0 OUTPUT)
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
								
	 - 20120223@Peter:
					 http://ccs.nexcel.vn/viewtopic.php?f=4&t=6247
					Final decision confirmed by our Management :
					1)To take away the ‘Adjustment’ formula in the Affiliate System : Affiliate Monthly Commission = (Company Net Winloss - Bonus) * commission percent
					2) Although the ‘Adjustment’ is taken out from the formula but we still maintain this column inside the system.
	 - 20120511@Peter : Add Casino Commission to formula
					http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
	 
	 - 20120115@Peter : Modify Casino negative commission
					 http://ccs.nexcel.vn/viewtopic.php?f=6&t=7524&p=35897#p35897 

	- 20120514@Peter : Apply new formula according to Joycee's request

			 IF Winloss in SPORTSBOOK > winloss in Casino then 
				 
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe
					Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee
			 else
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee
				   Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee
   

*/
BEGIN	
  
 SET NOCOUNT ON


Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int,@SportsBookID int,@HorseRacingID int,@CasinoID int,@MarketingTransType int,@DeductionPercent float, @MinimumNegativeCommission float, @MinimumNegativeCasinoCommission float

select @MinimumNegativeCommission = 0.1,  @MinimumNegativeCasinoCommission=0.05

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'),@CasinoID=dbo.Aff_GetSportID('Casino')


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))


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
	PlayTechRoyaltiesPercent float,
	IsPSPIncluded int -- flag to check PSP Fee is included or not for this product 
)

INSERT INTO @AffSummary(AffID,Currency,GroupID,SportID,MemWinlost,MemBonus,MemAdjustment,MemPSP,Marketing,MemDeposit,MemTurnover,TotalQM,BonusPercent,AdjustmentPercent,MarketingPercent,PSPPercent,OddsFeePercent,PlayTechRoyaltiesPercent,IsPSPIncluded)

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

declare @PSP money, @maxwinlost money, @maxWinlostSportID int

select @PSP=MemPSP
from @AffSummary a
where a.SportID=@SportsBookID

select @maxwinlost=max(abs(MemWinlost)) from @AffSummary

select top(1) @maxWinlostSportID=sportid
from @AffSummary
where abs(MemWinlost)=@maxwinlost and SportID <> @SportsBookID

select @maxWinlostSportID=coalesce(@maxWinlostSportID,@SportsBookID), @PSP=coalesce(@PSP,0)


update a

set a.IsPSPIncluded=1

from @AffSummary a

where a.sportid=@maxWinlostSportID


--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID

update a
set  a.NetWinlost=(-isnull(a.MemWinlost,0) 
				 - isnull(@PSP,0)*isnull(a.PSPPercent,0) * a.IsPSPIncluded
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
																 - isnull(@PSP,0)*isnull(a.PSPPercent,0) * a.IsPSPIncluded
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
	  -- and a.SportID in (@SportsBookID, @CasinoID)
	  and a.GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')
		and a.SportID in (
		select distinct SportID from GroupSettingHistory (nolock) where GroupID=a.GroupID and DATEDIFF(m,MonthDate,@LastDay)=0
	  )    



/*select @Amount=sum((a.NetWinlost- Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1) - Cast(a.HasAdjustment as int) *  isnull(a.MemAdjustment,0) * isnull(a.AdjustmentPercent,1))*isnull(a.Commission,0))*/
select @Amount=sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0))
from  @AffSummary a
where SportID = @SportsBookID

select @CAAmount=sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0))
from  @AffSummary a
where SportID = @CasinoID


select @SPCommission= a.Commission
	, @QualifiedMembers = TotalQM
from  @AffSummary a
where SportID=@SportsBookID

 
select @HRCommission=a.Commission
from  @AffSummary a
where SportID=@HorseRacingID

select @CACommission= a.Commission
	, @CAQualifiedMembers = TotalQM
from  @AffSummary a
where SportID=@CasinoID
   
END

GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarning] TO [vnteam]