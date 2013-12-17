ALTER PROCEDURE [dbo].[Aff_EarningSelDaily]  
	@AffID int,	
	@SportType tinyint = 0,
	@monthdate smalldatetime,
	@MarketingPercent float=0 OUTPUT,
	@OddsFeePercent float=0 OUTPUT,
	@PSPFeePercent float=0 OUTPUT,
	@CasinoMarketingPercent float=0 OUTPUT,
	@PLayTechFeePercent float=0 OUTPUT   
AS  
/*
	Created: 200900911@VinhTrinh 
	Task : [description of SP]  
	DB: DB052.Affiliate_12BET
	Revisions:  		
		  - Get data for daily report from table AffDaily instead of MemberDaily
		  - 20100520@Johnny: apply StatusID in bettrans table
		  - 20100930@Peter : Change the new formula for displayed winlost
					   Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
					   --The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
					   MemWinlostFake need to be updated on TaskMemberDaily
		  - 20101228@Henry: change bettype to new range
		  - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		  - 20120606@Peter : Exclude waiting tickets
	Param's Explanation:  
	• @custid: affliate Id  
	• @monthdate: Month date need to view.
	
	
	  
*/  
SET NOCOUNT ON
DECLARE @CurrDate smalldatetime, @fromdate smalldatetime, @todate smalldatetime, @SportsBookID int
	, @HorseRacingID int, @CasinoId int--,@MarketingPercent float,@OddsFeePercent float
	
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'), @CasinoId = dbo.Aff_GetSportID('Casino')
SET @CurrDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)
select @monthdate = dateadd(d, datediff(d, 0, @monthdate), 0)
	

Select @MarketingPercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'Marketing', @monthdate), 0)
Select @OddsFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'Odds Fee', @monthdate), 0)
Select @PSPFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @SportsBookID, 'PSP', @monthdate), 0)
Select @PLayTechFeePercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @CasinoId, 'PlayTech Royalties', @monthdate), 0)
select @CasinoMarketingPercent = isnull(dbo.[Aff_GetDeductionPercent](@AffId, @CasinoId, 'Marketing', @monthdate), 0)


Select @fromdate = DATEADD(mm, DATEDIFF(m,0,@monthdate),0)
Select @todate = case when @monthdate >= @CurrDate then dateadd(d, -1, @CurrDate) else @monthdate end

IF @monthdate >= @CurrDate
Begin
	SELECT 
		d.winlostdate, 					
		sum(d.MemDeposit) as Deposit,
		sum(d.MemWithdrawal) as Withdrawal,
		sum(d.MemWinlost) as MemberWinlost,
		sum(d.MemWinlostFake) as MemWinlostFake,
		sum(d.MemBonus) as Bonus,
		sum(d.MemAdjustment) as Adjustment,
		sum(d.MemPSP) as PSP
	FROM AffDailySummary d with(nolock)			     
	WHERE AffID = @AffID		
		AND (case when SportId <> 3 and d.winlostdate between @fromdate and @todate then 1
				when SportId = 3 and d.winlostdate between @fromdate and @CurrDate then 1
				else 0 end) = 1
		and (case when @SportType = 0 or @SportType = SportId then 1 else 0 end) = 1
		and (isnull(MemTurnOver,0) <>0 or isnull(MemWinlost,0)<>0 or isnull(MemBonus,0)<>0 or isnull(MemAdjustment,0)<>0 or isnull(MemPSP,0)<>0 or isnull(MemMarketing,0)<>0 or isnull(MemDeposit,0)<>0 or isnull(MemWithdrawal,0)<>0)			
	group by d.winlostdate
	
	UNION ALL
	select  winlostdate,sum(Deposit) as Deposit,sum(Withdrawal) as Withdrawal,sum(MemberWinlost) as MemberWinlost,	
		   -sum(-isnull(MemberWinlost,0) 
				- PSP
				-  abs(isnull(MemberWinlost,0)) * @OddsFeePercent 
				-  abs(isnull(MemberWinlost,0)) * @MarketingPercent
				)               	
			as MemWinlostFake ,
			sum(Bonus) as Bonus,sum(Adjustment) as Adjustment,sum(PSP) as PSP

	From
	(       	  
			SELECT 
				@CurrDate as winlostdate, 
				isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype = 22001 then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) as Deposit,
				-isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype in (22002,22003) then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) as Withdrawal,
				
				isnull(sum(case 
					when @SportType = 0 and bettype < 999 then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
					when @SportType = @SportsBookID and bettype < 999  and bettype not in (31,32,33,41,42,43) then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
					when @SportType = @HorseRacingID and bettype < 999 and bettype in (31,32,33,41,42,43) then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2
					else 0 end)
				,0) as MemberWinLost,
				isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype = 22004 then (winlost-abs(actual_stake))* e.ActualRate2 else 0 end),0) as Bonus,
				isnull(sum(case when (@SportType = @SportsBookID or @SportType = 0) and bettype in (21001, 21002, 21003, 21004, 21005, 22005) then (winlost-abs(actual_stake))* e.ActualRate2 else 0 end),0) as Adjustment,		
				isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype = 22001 then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0) * e.DepositPercent
				+ abs(-isnull(sum(case when (@SportType = 0 or @SportType = @SportsBookID) and bettype in (22002,22003) then (winlost-abs(actual_stake)) * e.ActualRate2 else 0 end),0)) * e.WithdrawalPercent
				 as PSP

			FROM bodb02.dbo.bettrans b with(nolock)
				inner join 
					(select IBCCustID, Currency 
					from MemberInfo with(nolock) 
					where AffID = @AffID and IsRemoved = 0) m on m.IBCCustID = b.CustId						
				INNER JOIN Exchange_current e WITH (NOLOCK) ON e.Exchangeid=m.Currency     
			WHERE @SportType <> @CasinoId
				and b.Winlostdate = @CurrDate 
				and b.ruben = 1 
				and (bettype<999 or bettype in (22001,22004,21001, 21002, 21003, 21004, 21005, 22005,22002,22003) ) 
				 and bettype not between 31 and 120 --Not include Casino and Number Game
				and StatusID not in (101, 102, 103, 121,1)
				--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING') 
			group by e.DepositPercent,e.WithdrawalPercent 
	) t
	
	group by t.winlostdate
	order by winlostdate
END	
else
Begin
	SELECT 
		d.winlostdate, 					
		sum(d.MemDeposit) as Deposit,
		sum(d.MemWithdrawal) as Withdrawal,
		sum(d.MemWinlost) as MemberWinlost,
		sum(d.MemWinlostFake) as MemWinlostFake,
		sum(d.MemBonus) as Bonus,
		sum(d.MemAdjustment) as Adjustment,
		sum(d.MemPSP) as PSP
	FROM AffDailySummary d with(nolock)			 
	WHERE AffID = @AffID		
		AND d.winlostdate between @fromdate and @todate
		and (case when @SportType = 0 then 1 when @SportType = SportId then 1 else 0 end) = 1
		and (isnull(MemTurnOver,0) <>0 or isnull(MemWinlost,0)<>0 or isnull(MemBonus,0)<>0 or isnull(MemAdjustment,0)<>0 or isnull(MemPSP,0)<>0 or isnull(MemMarketing,0)<>0 or isnull(MemDeposit,0)<>0 or isnull(MemWithdrawal,0)<>0)			
	group by d.winlostdate
	order by d.winlostdate
End			
		


GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EarningSelDaily] TO [vnteam]