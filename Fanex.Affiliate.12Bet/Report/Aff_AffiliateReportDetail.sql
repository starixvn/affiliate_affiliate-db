Alter Procedure [Aff_AffiliateReportDetail]
	@AffUsername varchar(50),
	@AffId int = 0 OUTPUT,
	@Fromdate datetime,
	@Todate datetime,
	@SportId int = null,
	@IsGetAll bit = 0
AS
/*
	DB052.Affiliate_12BET
	Revisions:
	- 20101228@Henry: change bettype to new range
	- 20110420@Johnny: Filter by Sporttype and restore code to old bettype range
	 - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	 - 20120606@Peter : Exclude waiting tickets
*/
select @AffId = AffId from AffInfo with(nolock) where Username = @AffUsername

if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

if @AffId = 0 --Invalid AffUsername
	return
	
Declare @CurrDate smalldatetime, @OldReportDate smalldatetime, @TmpFromDate smalldatetime, @TmpToDate smalldatetime, @TmpOldWayDate smalldatetime
		, @SportsBookID int, @HorseRacingID int
	
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing')




select @CurrDate = convert(varchar(10),current_timestamp,120)

select @ToDate = dateadd(s, -60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

Select @OldReportDate=SValue
from SystemSettings with (nolock)
where SName='AFF_OldReportDate'

if(@OldReportDate is null)
  select @OldReportDate='31 Oct 2009'
  

if @IsGetAll = 1
Begin
	select @FromDate = min(WinlostDate) from MemberDaily with (nolock)
	select @ToDate = current_timestamp
	
	select @TmpFromDate = dateadd(d, 1, @OldReportDate)--From date for new way calculate winlost
	select @TmpToDate = dateadd(d, -1, @CurrDate)--To date for new way calculate winlost
	select @TmpOldWayDate = @OldReportDate	
End
Else
Begin
	select @TmpFromDate = case when @FromDate <= @OldReportDate then dateadd(d, 1, @OldReportDate) else @FromDate end
	select @TmpToDate = case when @ToDate >= @CurrDate then dateadd(d, -1, @CurrDate) else @ToDate end
	select @TmpOldWayDate = case when @ToDate >= @OldReportDate then @OldReportDate else @ToDate end
End


select WinlostDate,
	AffExRate,
	e.Currency,
	Sum(b.Deposit) as Deposit,
	Sum(b.Withdrawal) as Withdrawal,
	Sum(b.Turnover) as Turnover,
	Sum(b.Winlost) as Winlost,
	Sum(b.Bonus) as Bonus,
	Sum(b.PSP) as PSP,
	Sum(b.Adjustment) as Adjustment,
	Sum(b.AffAdjustment) as AffAdjustment,
	Sum(b.AffWithdrawal) as AffWithdrawal,
	Sum(b.AffBF) as AffBF
From Exchange_Current e with (nolock)
	inner join
	(	
		Select WinlostDate,--Calculate winlost member below Aff in MemberDaily and AffCommission table
			Currency,
			ExRate2 as AffExRate,
			Sum(MemDeposit) as Deposit,
			Sum(MemWithdrawal) as Withdrawal,
			Sum(MemTurnover) as Turnover,
			Sum(MemWinlost) as Winlost,
			Sum(MemBonus) as Bonus,
			Sum(MemPSP) as PSP,
			Sum(MemAdjustment) as Adjustment,
			0 as AffAdjustment,
			0 as AffWithdrawal,
			sum(AffNetWinlost) as AffBF
		From AffDaily with(nolock)
		Where 
			(case when SportId < 3 and WinlostDate Between @FromDate and @TmpToDate then 1
					when SportId = 3 and WinlostDate Between @FromDate and @ToDate then 1
					else 0 end) = 1
			--WinlostDate Between @FromDate and @TmpToDate
			and AffId = @AffId
			and isnull(@SportId, SPortId) = SPortId

		Group by WinlostDate, Currency, ExRate2
		
		Union All
		
		Select @CurrDate as WinlostDate,--Get winlost member in Bettrans table
			m.Currency,
			e.ActualRate2 as AffExRate,
			case when (@SportId is null or @SportId = @SportsBookID) and bettype=22001 then 
					isnull(sum(winlost-abs(actual_stake)),0)
				else 0 end as Deposit,
			
			case when (@SportId is null or @SportId = @SportsBookID) and bettype in (22002,22003) then 
					-isnull(sum(winlost-abs(actual_stake)),0)
				else 0 end as Withdrawal,
				
			case when @SportId is null and bettype < 19000 then
					isnull(sum(case when Bettype in (33,43) and liveawayscore = 0 then isnull(abs(stake), 0) / 2 else isnull(abs(stake), 0) end),0)
				when @SportId = @SportsBookID and BetType < 19000 and bettype not in (31,32,33,41,42,43) then
					isnull(sum(isnull(abs(stake), 0)), 0)
				When @SportId = @HorseRacingID and bettype in (31,32,33,41,42,43) then
					isnull(sum(case when Bettype in (33,43) and liveawayscore = 0 then isnull(abs(stake), 0) / 2 else isnull(abs(stake), 0) end),0)
				else 0 end as Turnover,
			
			case when @SportId is null then  
					isnull(sum(case when bettype < 19000 and ruben=1 then (winlost-abs(actual_stake)) else 0 end),0)
				when @SportId = @SportsBookID then
					isnull(sum(case when bettype < 19000 and ruben=1 and bettype not in(31,32,33,41,42,43) then (winlost-abs(actual_stake)) else 0 end),0)
				when @SportId = @HorseRacingID then
					isnull(sum(case when bettype in(31,32,33,41,42,43) and ruben=1 then (winlost-abs(actual_stake)) else 0 end),0)				
				else 0 end as Winlost,
						
			case when (@SportId is null or @SportId = @SportsBookID) and bettype = 22004 then  
					isnull(sum((winlost-abs(actual_stake))),0)
				else 0 end  as Bonus,
				
			case when @SportId is null or @SportId = @SportsBookID then  
					isnull(sum(case bettype when 22001 then (winlost-abs(actual_stake)) else 0 end),0) * e.DepositPercent
					+ abs(-isnull(sum(case when bettype in (22002,22003) then (winlost-abs(actual_stake)) else 0 end),0)) * e.WithdrawalPercent
				else 0 end as PSP,
				
			case when @SportId is null or @SportId = @SportsBookID and bettype in (21001, 21002, 21003, 21004, 21005, 22005) then  
					isnull(sum((winlost-abs(actual_stake))),0)
				else 0 end as Adjustment,
			0 as AffAdjustment,
			0 as AffWithdrawal,
			0 as AffBF
		From bodb02.dbo.Bettrans b with (nolock)
			inner join MemberInfo m with (nolock) on m.IBCCustID = b.CustId and m.AffId = @AffId and m.IsRemoved = 0
			inner join  Exchange_Current e with (nolock)  on m.Currency = e.ExchangeId
		where @ToDate >= @CurrDate 
			and b.WinlostDate = @CurrDate
			and (Bettype < 19000 or Bettype in (21001, 21002, 21003, 21004, 21005, 22001, 22002,22003, 22004, 22005))
			 and bettype not between 71 and 120 --Not include Casino and Number Game
			and StatusID not in (101, 102, 103, 121,1)
			--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WATING')
		Group by b.WinlostDate, m.Currency, e.ActualRate2,e.DepositPercent,e.WithdrawalPercent, b.Bettype
		
		Union All
		
		select dateadd(d, datediff(d, 0, a.TransDate), 0) as WinlostDate,--Get Aff Adjusment and Aff Widthrawal
			a.Currency,
			1 as AffExRate,--Default currency $US for Aff
			0 as Deposit,
			0 as Withdrawal,
			0 as Turnover,
			0 as Winlost,
			0 as Bonus,
			0 as PSP,
			0 as Adjustment,
			Sum(case when Transtype = 203 then Amount else 0 end) as AffAdjustment,
			Sum(case when Transtype = 202 then Amount else 0 end) as AffWithdrawal,
			0 as AffBF
		From AffTrans a with (nolock)
		where (@IsGetAll = 1 or TransDate between @FromDate and @ToDate)
			and Transtype in (202, 203)
			and status in ('Pending', 'Approved', 'Completed')
			and a.AffId = @AffId
		Group by dateadd(d, datediff(d, 0, a.TransDate), 0), a.Currency
	) b on b.Currency = e.ExchangeID
	Group by WinlostDate, AffExRate, e.Currency
	order by WinlostDate


GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateReportDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReportDetail] TO [VNTeam] 

