USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CalMonthlyEarningCurrent]    Script Date: 05/14/2013 01:41:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarningCurrent    Script Date: 1/18/2013 6:02:37 AM ******/
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarningCurrent    Script Date: 1/16/2013 5:19:01 PM ******/
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarningCurrent    Script Date: 11/1/2011 12:48:31 PM ******/
ALTER PROCEDURE [dbo].[Aff_CalMonthlyEarningCurrent] (
@AffID int,
--@TodayPSP money=0, --PSP Get from Deposit DB
@QualifiedMembers int = 0 output,
@CAQualifiedMembers int = 0 output,
@CAAmount  money = 0 OUTPUT, -- Amount with Marketing Fee included for Casino
@Amount money OUTPUT, -- Amount with Marketing Fee included
@SPCommission float OUTPUT,
@HRCommission float OUTPUT,
@CACommission float = 0 OUTPUT)
AS
/*
	Task : Calculate monthy earning for affiliate current month
	DB: DB052.Affiliate_12BET
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
	- 20101228@Henry: change bettype to new range
	- 20110816@Johnny: Output one more result "QualifiedMembers".
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
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

Declare  @Today smalldatetime,@FirstDay smalldatetime,@LastDay smalldatetime,@TransType int,@SportsBookID int,@HorseRacingID int,@CasinoID int,@MarketingTransType int,@DeductionPercent float, @MinimumNegativeCommission float, @MinimumNegativeCasinoCommission float

select @MinimumNegativeCommission = 0.1,  @MinimumNegativeCasinoCommission=0.05

select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'),@CasinoID=dbo.Aff_GetSportID('Casino')

Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @Today = convert (varchar(12),current_timestamp)
select @LastDay=dateadd(d,-1,@Today) 


Declare @AffSummary Table
(
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

					  
 Declare @GroupID int
   
  Select @GroupID=GroupID
   from AffInfo (nolock)
   Where AffID=@AffID
   --No need to get PSP from Deposit DB
   /*Select @TodayPSP=Sum(PSP * AffExRate)
   from MemberDaily (nolock)
  where AffID=@AffID and WinlostDate=@Today*/

INSERT INTO @AffSummary(
	SportID,
	MemWinlost ,
	MemBonus ,
	MemAdjustment ,
	MemPSP ,
	Marketing ,
	MemDeposit ,
	MemTurnover ,	
	TotalQM ,  	
	BonusPercent ,
	MarketingPercent ,
	AdjustmentPercent ,
	PSPPercent ,
	OddsFeePercent ,
	PlayTechRoyaltiesPercent,
	IsPSPIncluded )

Select  r.SportType as SportID
	   ,sum(isnull(r.Winlost,0)) as MemWinlost
	   ,sum(isnull(r.Bonus,0)) as MemBonus
	   ,sum(isnull(r.Adjustment,0)) as MemAdjustment
	   ,sum(isnull(r.PSP,0)) as MemPSP
	   ,sum(isnull(r.Marketing,0)) as Marketing  
		,sum(isnull(r.Deposit,0)) as MemDeposit	     
	   ,sum(isnull(r.Turnover,0)) as MemTurnover
	   ,sum(case when r.TurnOver>=s.QMTurnOver and r.Deposit>=s.QMDeposit then 1 else 0 end) as TotalQM      	   	   
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'Bonus',null) as BonusPercent	   
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'Marketing',null) as MarketingPercent
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'Adjustment',null) as AdjustmentPercent
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'PSP',null) as PercentPSP
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'Odds Fee',null) as OddsFeePercent
	   ,dbo.Aff_GetDeductionPercent(@AffID,r.SportType,'PlayTech Royalties',null) as PlayTechRoyaltiesPercent
	   ,0 as IsPSPIncluded
   
FROM  
	  (
		select md.IBCCustID,md.SportType
			   ,sum(isnull(md.Winlost,0) * isnull(md.AffExRate,1)) as Winlost
			   ,sum(isnull(md.Bonus,0) * isnull(md.AffExRate,1)) as Bonus
			   ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment
			   ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP
			   ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing
			   ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver
			   ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit				   
		from 
		(
			Select IBCCustID,SportType,Winlost,Bonus,Adjustment,PSP,Marketing,TurnOver,AffExRate,Currency,Deposit
			From MemberDaily md  (nolock)               
			where AffID=@AffID and WinlostDate between @FirstDay and @LastDay             
			UNION ALL
			-- addd casino data for current day
			
			Select IBCCustID,SportType,Winlost,Bonus,Adjustment,PSP,Marketing,TurnOver,AffExRate,Currency,Deposit
			From MemberDaily md  (nolock)               
			where AffID=@AffID and WinlostDate=@Today and SportType not in (@SportsBookID,@HorseRacingID)
			UNION ALL
			select 
					ci.IBCCustID, 					
					case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end as SportType,	
					isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Deposit,				
					isnull(sum(case when bettype < 19000 AND ruben = 1 then (b.Winlost -abs(b.actual_stake)) else 0 end), 0) as Winlost, 					
					isnull(sum(case bettype when 22004 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Bonus,
					isnull(sum(case when bettype in (21001, 21002, 21003, 21004, 21005, 22005) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) as Adjustment,				
					isnull(sum(case bettype when 22001 then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0) * e.DepositPercent
					+  abs(-isnull(sum(case when bettype in (22002,22003) then isnull(winlost,0)-isnull(abs(actual_stake),0) else 0 end),0)*e.WithdrawalPercent)
							as PSP,
					0 as Marketing,
					isnull(sum(case when bettype < 19000 then 
								(case when Bettype in (33,43) and liveawayscore = 0 then isnull(abs(stake), 0) / 2 * e.Actualrate2 else isnull(abs(stake), 0) end)
							else 0 end),0) as Turnover,
					e.Actualrate2 as AffExRate,
					e.exchangeid as exchangeid					
				from MemberInfo ci with (nolock)
					inner join bodb02.dbo.bettrans b with (nolock) on b.custid = ci.IBCCustID
					INNER JOIN Exchange_Current e with (nolock)  on e.exchangeid=ci.currency  
				where b.winlostdate=@Today
					and ci.AffID=@AffID
					and ci.IsRemoved = 0
					AND (Bettype < 19000  or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))		
					 and bettype not between 71 and 120 --Not include Casino and Number Game
					and StatusID not in (101, 102, 103, 121,1)
					--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')	
				Group by ci.IBCCustID, case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end,e.Actualrate2,e.exchangeid,e.DepositPercent,e.WithdrawalPercent

				
		
		) md
		group by IBCCustID,SportType
		

	  ) r 
	  left join SportType s (nolock) on s.SportID=r.SportType 
group by r.SportType
 

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
set   a.NetWinlost=(-isnull(a.MemWinlost,0) 
				 - isnull(@PSP,0)*isnull(a.PSPPercent,0) * a.IsPSPIncluded
				 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0) 
				- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0) 
				- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0) 
				),
	  a.commission=isnull((select  top(1) Commission
						  from 
							(
								select isnull((select Commission
											  from GroupSetting(nolock)
											  where GroupID=@GroupID 
													and SportType=a.SportID													
													and floor(
															  abs(
																 -isnull(a.MemWinlost,0) 
																 - isnull(@PSP,0)*isnull(a.PSPPercent,0) * a.IsPSPIncluded
																 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0) 
																- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0) 
																- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0) 
																)
															) 
														between MinAmount and MaxAmount),0) as Commission
								union all                             
								  select isnull((select top(1) Commission 
													  from GroupSetting(nolock)
													  where GroupID=@GroupID
															and SportType=a.SportID 															
															and a.TotalQM between MinQM and MaxQM
												   ),0)
										   as Commission
							) t  
							order by t.Commission asc
					),0)
from @AffSummary a

if @GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')
begin
update a
set a.Commission = (case when a.SportID=@CasinoID then @MinimumNegativeCasinoCommission else @MinimumNegativeCommission end)
from @AffSummary a
where a.NetWinlost < 0 and a.Commission = 0	 
   and a.SportID in (
		select distinct SportID from GroupSetting (nolock) where GroupID=@GroupID	
	  )   
end     
	  


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
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [vnteam]