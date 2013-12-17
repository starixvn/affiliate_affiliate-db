ALTER PROCEDURE [dbo].[Aff_ReportDetailSelAll]
	@Fromdate datetime,
	@Todate datetime

AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
	 Three cases to calculate report:
	  + @Todate<=@OldReportDate ---> use old formula
	  + @FromDate>@OldReportDate
		 . @FromDate --> @MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
		 . @MaxTransDate + 1 --> @Todate-1: use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
		 . @CurDate : from bettrans	 and cannot calculate Affiliate Winlost and House Winlost
	  + @FromDate-->@OldReportDate-->@Todate:
		 .@FromDate -->@OldReportDate:use old formula
		 .@OldReportDate + 1 --->@MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
		 .@MaxTransDate +1 --->@Todate-1 :use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
		 . @CurDate : from bettrans	 and cannot calculate Affiliate Winlost and House Winlost 	   
DB: DB052.Affiliate_12BET
Original: [Aff_ReportDetailSelAll]
Revisions:
	- 20101228@Henry: change bettype to new range
	- 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	- 20120606@Peter : Exclude waiting tickets
Param's Explanation:
	• @Fromdate Month search from
	• @Todate To month.
*/

SET NOCOUNT ON
if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

declare @CurrDate smalldatetime, @MaxTransDate smalldatetime,@OldReportDate smalldatetime,@TmpToDate smalldatetime
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

   
Select t.* 
from
(
	(
		Select Winlostdate, 
			a.Currency as exchangeID, 
			e.Currency, 
			a.ExRate2 as Actualrate, 
			isnull(Sum(MemDeposit), 0) as Deposit,
			isnull(Sum(MemTurnover), 0) as Turnover,			
			isnull(Sum(MemBonus), 0) as Bonus,
			isnull(Sum(MemWinLost), 0) as MemberWinLost,
			isnull(Sum(AffWinLost), 0) as AffiliateWinLost,
			isnull(Sum(HouseWinLost), 0) as HouseWinLost,
			isnull(Sum(AffNetWinLost), 0) as AffiliateNetWinLost,
			isnull(Sum(HouseNetWinLost), 0) as HouseNetWinLost
		From AffDaily a with(nolock)
			inner join Exchange_Current e with(nolock) on a.Currency = e.ExchangeID
		Where winlostdate between @FromDate and @TmpToDate
		Group By Winlostdate, a.Currency, e.Currency, a.ExRate2
	)
	
	union all

	(
		select 
			@CurrDate as Winlostdate, 
			b.Currency as exchangeID, 
			e.Currency, 
			e.ActualRate2 as Actualrate, 
			isnull(sum(case bettype when 22001 then b.winlost-abs(b.actual_stake) else 0 end),0) as Deposit,
			sum(case when bettype < 19000 then 
					(case when Bettype in (33,43) and liveawayscore = 0 then isnull(abs(stake), 0) / 2 else isnull(abs(stake), 0) end)
				else 0 end) as Turnover,
			--isnull(sum(case when bettype < 19000 then stake else 0 end),0) as Turnover,
			isnull(sum(case bettype when 22004 then winlost-abs(actual_stake) else 0 end),0) as Bonus,
			isnull(sum(case when bettype < 19000 and ruben=1 then winlost-abs(actual_stake)+playercomm else 0 end),0) as MemberWinLost,
			null as AffiliateWinLost,
			null as HouseWinLost,
			null as AffiliateNetWinLost,
			null as HouseNetWinLost
		 FROM bodb02.dbo.bettrans b with(nolock)	
			inner join MemberInfo m with(nolock) on b.CustId = m.IBCCustId and m.IsRemoved = 0								   						
			inner join Exchange_Current e with (nolock) on e.exchangeid=b.currency 	

		 WHERE @ToDate>=@CurrDate 
			   and b.Winlostdate = @CurrDate
			   and (bettype<19000 or bettype in (22001,22004))
			  and bettype not between 71 and 120 --Not include Casino and Number Game
			   and StatusID not in (101, 102, 103, 121,1)
			   --and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')
		group by b.Currency, e.Currency, e.ActualRate2
	)
) t
order by t.Winlostdate, t.Currency


GO

GRANT EXECUTE ON [dbo].[Aff_ReportDetailSelAll] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportDetailSelAll] TO [VNTeam] 