ALTER PROCEDURE [dbo].[Aff_AffiliateDailySelForImport]      
	@AffID int,      
	@Fromdate datetime,      
	@Todate datetime      
AS      
/*      
Created: @Johnny    
Task : Get daily data for inserting to AffDaily table    
 Three cases to calculate report:      
 + @Todate<=@OldReportDate ---> use old formula      
 + @FromDate>@OldReportDate      
 . @FromDate --> @MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)      
 . @MaxTransDate + 1 --> @Todate-1: use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost      
 + @FromDate-->@OldReportDate-->@Todate:      
 .@FromDate -->@OldReportDate:use old formula      
 .@OldReportDate + 1 --->@MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)      
 .@MaxTransDate +1 --->@Todate-1 :use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost      
    
DB: DB052.Affiliate_12BET      
Original: [Aff_AffiliateDailySel]      
Revisions:      
    
Param's Explanation:    
• @AffID Affiliate ID    
• @Fromdate Month search from      
• @Todate To month.      
    
*/      
SET NOCOUNT ON      
if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN      
    
declare @CurrDate smalldatetime, @MaxTransDate smalldatetime,@OldReportDate smalldatetime,@TmpToDate smalldatetime      
declare @SportsBookID tinyint, @HRID int    
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'), @HRID=dbo.Aff_GetSportID('Horse Racing')    
    
Select @OldReportDate=SValue      
from SystemSettings with (nolock)      
where SName='AFF_OldReportDate'      
if(@OldReportDate is null)      
	select @OldReportDate='31 Oct 2009'      
    
    
select @CurrDate =  convert(varchar(10),current_timestamp,120),      
		@Fromdate = convert(varchar(10),@Fromdate,120),      
		@Todate = convert(varchar(10),@Todate,120)      
Select @TmpToDate=@ToDate     
     
if(@Todate>=@CurrDate)      
	select @TmpToDate=dateadd(d,-1,@CurrDate)       
    
If @Todate<=@OldReportDate      
Begin      
--print '1'      
	select @AffID as AffID,     
		d.Currency as Currency,       
		d.Winlostdate as Winlostdate,           
		@SportsBookID as SportID,      
		d.AffExRate as Exrate2,     
		SUM(isnull(d.Deposit,0)) as MemDeposit,      
		SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,      
		SUM(isnull(d.Turnover,0)) as MemTurnover,       
		SUM(isnull(d.Bonus,0)) as MemBonus,    
		SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
		SUM(isnull(d.Marketing,0)) as MemMarketing,    
		SUM(isnull(d.PSP,0)) as MemPSP,    
		SUM(isnull(d.Winlost,0)) as MemWinLost,        
		SUM(isnull(d.AWinLost, 0)) as AffWinLost,      
		-SUM(isnull(d.Winlost,0) + isnull(d.AWinLost, 0)) as HouseWinLost,        
		sum(isnull(d.Awinlost,0) + isnull(d.aBonus,0)) as AffNetWinlost,      
		-sum(isnull(d.Winlost,0)+isnull(d.Awinlost,0) +isnull(d.Bonus,0) + isnull(d.aBonus,0)) as HouseNetWinLost      
	FROM MemberDaily d with (nolock)                 
		INNER JOIN Exchange_Current e with (nolock) on d.currency = e.exchangeid      
	WHERE d.Winlostdate between @FromDate and @Todate      
		and d.AffID=@AffID       
		and (isnull(d.TurnOver,0) <>0 or isnull(d.Winlost,0)<>0 or isnull(d.Bonus,0)<>0 or isnull(d.Adjustment,0)<>0 or isnull(d.PSP,0)<>0 or isnull(d.Marketing,0)<>0 or isnull(d.Deposit,0)<>0 or isnull(d.Withdrawal,0)<>0)
	GROUP BY d.Winlostdate, d.Currency, d.AffExRate      
	order by Winlostdate    
End      
else if @FromDate>@OldReportDate      
Begin      
--  print '2'        
/*select @MaxTransDate = max(WinlostDate) from affcommission with(nolock)*/      
	Select t.*       
	from      
	(      
		select @AffID as AffID,      
			d.Currency as Currency,       
			d.Winlostdate as Winlostdate,       
			d.SportType as SportID,      
			d.AffExRate as Exrate2,       
			SUM(isnull(d.Deposit, 0)) as MemDeposit,   
			SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,       
			SUM(isnull(d.Turnover, 0)) as MemTurnover,       
			SUM(isnull(d.Bonus, 0)) as MemBonus,    
			SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
			SUM(isnull(d.Marketing,0)) as MemMarketing,    
			SUM(isnull(d.PSP,0)) as MemPSP,        
			SUM(isnull(d.Winlost, 0)) as MemWinLost,        
			-SUM(isnull(d.WinLost, 0) * isnull(ac.Commission, 0)) as AffWinLost,      
			-SUM(d.Winlost*(1-isnull(ac.Commission, 0))) as HouseWinLost,        
			-SUM(isnull(ac.Commission, 0) * ( isnull(d.WinLost,0)       
			+ isnull(d.bonus,0) *isnull(hasBonus,0)      
			+ isnull(d.Adjustment,0) * isnull(hasAdjustment,0)        
			+ isnull(d.PSP,0) * isnull(hasPSP,0)       
			+ isnull(d.Marketing,0)*isnull(hasMarketing,0)      
			)      
			) as AffNetWinlost,      
			-SUM(d.Winlost * (1-isnull(ac.Commission, 0))      
			+ isnull(d.Bonus,0) * (1-isnull(ac.Commission, 0) * isnull(hasBonus,0))      
			+ isnull(d.Adjustment,0) * (1-isnull(ac.Commission, 0) * isnull(hasAdjustment,0))      
			+ isnull(d.PSP,0) * (1-isnull(ac.Commission, 0) * isnull(hasPSP,0))      
			+ isnull(d.Marketing,0) * (1-isnull(ac.Commission, 0) * isnull(hasMarketing,0))      
			)      
			as HouseNetWinLost      
		from MemberDaily d with (nolock)      
			left join AffCommission ac with(nolock) on ac.AffId = d.AffID and ac.SportID = d.SportType and datediff(mm, d.WinlostDate, ac.WinlostDate) = 0      
			INNER JOIN Exchange_Current e with (nolock) on d.currency = e.exchangeid      
		where d.AffID=@AffID and d.WinlostDate between @FromDate and @TmpToDate                
		GROUP BY d.Winlostdate, d.Currency, d.SportType,d.AffExRate      
	) t       
	order by t.Winlostdate    
end      
else --@FromDate-->@OldReportDate-->@Todate      
begin      
-- print '3'      
    
Select t.*       
from      
(      
	(      
		select @AffID as AffID,      
			d.Currency as Currency,       
			d.Winlostdate as Winlostdate,        
			@SportsBookID as SportID,     
			d.AffExRate as Exrate2,     
			SUM(isnull(d.Deposit,0)) as MemDeposit,     
			SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,     
			SUM(isnull(d.Turnover,0)) as MemTurnover,       
			SUM(isnull(d.Bonus,0)) as MemBonus,    
			SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
			SUM(isnull(d.Marketing,0)) as MemMarketing,    
			SUM(isnull(d.PSP,0)) as MemPSP,          
			SUM(isnull(d.Winlost,0)) as MemWinLost,        
			SUM(isnull(d.AWinLost, 0)) as AffWinLost,      
			-SUM(isnull(d.Winlost,0) + isnull(d.AWinLost, 0)) as HouseWinLost,        
			sum(isnull(Awinlost,0) + isnull(aBonus,0)) as AffNetWinlost,      
			-sum(isnull(Winlost,0)+isnull(Awinlost,0) +isnull(Bonus,0) + isnull(aBonus,0)) as HouseNetWinLost      
		FROM MemberDaily d with (nolock)                 
			INNER JOIN Exchange_Current e with (nolock) on d.currency = e.exchangeid      
		WHERE d.Winlostdate between @FromDate and @OldReportDate      
			and d.AffID=@AffID      
			and (isnull(d.TurnOver,0) <>0 or isnull(d.Winlost,0)<>0 or isnull(d.Bonus,0)<>0 or isnull(d.Adjustment,0)<>0 or isnull(d.PSP,0)<>0 or isnull(d.Marketing,0)<>0 or isnull(d.Deposit,0)<>0 or isnull(d.Withdrawal,0)<>0)
		GROUP BY d.Winlostdate, d.Currency, d.AffExRate      
	)      
	union all      
	(      
	select @AffID as AffID,      
	d.Currency as Currency,       
		d.Winlostdate as Winlostdate,      
		d.SportType as SportID,    
		d.AffExRate as Exrate2,       
		SUM(isnull(d.Deposit, 0)) as MemDeposit,    
		SUM(isnull(d.Withdrawal,0)) as MemWithdrawal,      
		SUM(isnull(d.Turnover, 0)) as MemTurnover,       
		SUM(isnull(d.Bonus, 0)) as MemBonus,    
		SUM(isnull(d.Adjustment,0)) as MemAdjustment,    
		SUM(isnull(d.Marketing,0)) as MemMarketing,    
		SUM(isnull(d.PSP,0)) as MemPSP,         
		SUM(isnull(d.Winlost, 0)) as MemWinLost,        
		-SUM(isnull(d.WinLost, 0) * isnull(ac.Commission, 0)) as AffWinLost,      
		-SUM(d.Winlost*(1-isnull(ac.Commission, 0))) as HouseWinLost,        
		-SUM(isnull(ac.Commission, 0) * ( isnull(d.WinLost,0)       
		+ isnull(d.bonus,0) *isnull(hasBonus,0)      
		+ isnull(d.Adjustment,0) * isnull(hasAdjustment,0)        
		+ isnull(d.PSP,0) * isnull(hasPSP,0)       
		+ isnull(d.Marketing,0)*isnull(hasMarketing,0)      
		)      
		) as AffNetWinlost,      
		-SUM(d.Winlost * (1-isnull(ac.Commission, 0))      
		+ isnull(d.Bonus,0) * (1-isnull(ac.Commission, 0) * isnull(hasBonus,0))      
		+ isnull(d.Adjustment,0) * (1-isnull(ac.Commission, 0) * isnull(hasAdjustment,0))      
		+ isnull(d.PSP,0) * (1-isnull(ac.Commission, 0) * isnull(hasPSP,0))      
		+ isnull(d.Marketing,0) * (1-isnull(ac.Commission, 0) * isnull(hasMarketing,0))      
		)      
		as HouseNetWinLost      
	from MemberDaily d with (nolock)      
		left join AffCommission ac with(nolock) on ac.AffId = d.AffID and ac.SportID = d.SportType and datediff(mm, d.WinlostDate, ac.WinlostDate) = 0      
		INNER JOIN Exchange_Current e with (nolock) on d.currency = e.exchangeid      
	where d.AffID=@AffID and  d.WinlostDate between dateadd(d,1,@OldReportDate) and @TmpToDate               
	GROUP BY d.Winlostdate, d.Currency, d.SportType, d.AffExRate      
	)        
) t      
order by t.Winlostdate    
end      