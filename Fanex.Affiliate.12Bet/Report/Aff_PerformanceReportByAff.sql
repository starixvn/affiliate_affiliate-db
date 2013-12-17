ALTER PROCEDURE [dbo].[Aff_PerformanceReportByAff]
	@AffId int,
	@SportId int = 1
AS
/*
Created: @VinhTrinh
Task : Get performance report for affiliate in range of time.
DB: DB052.Affiliate_12BET
Original: [Aff_PerformanceReportByAff]
Revisions:
	- 20110811@Johnny: Get last 6 months of affiliate performance report
	 - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
	 
	 - 20120606@Peter : Exclude waiting tickets
*/
Set Nocount On

Declare @Fromdate datetime, @SportBookId int, @CurrentDate smalldatetime, @LastMonthlydate smalldatetime, @FirstDate smalldatetime, @Date_Prev smalldatetime, @TmpToDate smallDateTime

select @CurrentDate = dateadd(d, 0, datediff(d, 0, current_timestamp))
Select @FromDate = dateadd(m, -5, @CurrentDate)--Last 6 months
		
--@FromDate equal 1st date of @fromdate
select @FromDate = DateAdd(m, datediff(m, 0, @FromDate), 0)--1st date of from date
		, @Date_Prev = DateAdd(m, -1, @CurrentDate)
		, @TmpToDate = DateAdd(d, -1, @CurrentDate)--To Exclude current date for calculating affdaily table
		, @SportBookId = 1
		
select @LastMonthlydate = max(WinlostDate) from AffCommission
select @FirstDate = dateadd(d, 1, @LastMonthlydate)
		
select dateadd(m, datediff(m, 0, t.Winlostdate), 0) as WinLostDate
			, Sum(isnull(QualifiedMember, 0)) as QualifiedMember
			, Sum(isnull(ActivePlayer, 0)) as ActivePlayer
			, Sum(isnull(MemberDeposit, 0)) as MemberDeposit
			, Sum(isnull(Withdrawal, 0)) as MemberWithdrawal--Affiliate withdrawal
			, Sum(isnull(MemberTurnover, 0)) as MemberTurnover
			, Sum(isnull(MemberWinlost, 0))as MemberWinlost
			, Sum(isnull(Commission, 0))as Commission   
from
	(
		--Calculate for the months are transferred
		select @SportId as SportId, WinlostDate, QualifiedMember, 0 as ActivePlayer, MemberDeposit, 0 as Withdrawal, MemberTurnover, MemberWinlost, AffWinlost as Commission		
		from AffCommission nolock
		where WinlostDate between @Fromdate and @LastMonthlydate
			and AffID = @AffId
			and SportId = @SportId
			
		union all
		
		--Calculate Withdrawal
		select @SportBookId as SportId, CompletedDate, 0 as QualifiedMember, 0 as ActivePlayer, 0 as MemberDeposit, Sum(isnull(Amount, 0)), 0 as MemberTurnover, 0 as MemberWinlost, 0 as Commission
		from AffTrans with (nolock) 
		where AffId = @AffId  and CompletedDate between @FromDate and @CurrentDate and transtype = 202 and Status = 'Approved'--For withdrawal 
		Group by CompletedDate
		
		Union all
		

		select c.SportID, 
			dateadd(m, datediff(m, 0, @CurrentDate), 0) as Winlostdate,
			c.TotalQM,
			0 as ActivePlayer,
			c.MemDeposit,
			0 as   Withdrawal,
			c.MemTurnOver,
			c.MemWinlost,
			c.Amount

		from  [Aff_CommissionForCurrentMonth](@AffId) as c
		where  c.SportID=@SportId
		
			  
		union all
		
		select c.SportID, 
			dateadd(m, datediff(m, 0, @Date_Prev), 0) as Winlostdate,
			c.TotalQM,
			0 as ActivePlayer,
			c.MemDeposit,
			0 as   Withdrawal,
			c.MemTurnOver,
			c.MemWinlost,
			c.Amount

		from  [Aff_CommissionForMonth](@AffId,MONTH(@Date_Prev),YEAR(@Date_Prev)) as c
		where DATEDIFF(m,@LastMonthlydate,@Date_Prev) >0 and
			 c.SportID=@SportId
				and @Date_Prev > @LastMonthlydate
		union all--Get total active players in previous month and current month
		
		select @SportId as SportId,
			dateadd(m, datediff(m, 0, Winlostdate), 0),
			0 as QualifiedMember,
			count(distinct IBCCustID) as ActivePlayer,
			0 as Deposit,
			0 as Withdrawal,
			0 as Turnover,			
			0 as WinLost,
			0 as Commission
		from Memberdaily nolock
		where AffId = @AffId
			and winlostdate between @FromDate and @CurrentDate 
			and (isnull(TurnOver,0) > 0 or isnull(Deposit,0) > 0)
			and SportType = @SportId
		group by dateadd(m, datediff(m, 0, Winlostdate), 0)
		 --Get data for the date that is not Monthly transfer yet
		/*Select @SportId as SportId,
			dateadd(m, datediff(m, 0, Winlostdate), 0) as Winlostdate,
			0 as QualifiedMember,
			0 as ActivePlayer,
			isnull(Sum(isnull(MemDeposit, 0) * ExRate2), 0) as Deposit,
			0 as Withdrawal,
			isnull(Sum(isnull(MemTurnover, 0) * ExRate2), 0) as Turnover,			
			isnull(Sum(isnull(MemWinLost, 0) * ExRate2), 0) as WinLost,
			0 as Commission
		From AffDaily a with(nolock)
		Where winlostdate between @FirstDate and @TmpToDate
			and a.AffId = @AffId
			and SportId = @SportId
		Group By dateadd(m, datediff(m, 0, Winlostdate), 0)
		
		union all
		
		select --Get data for current date
			@SportBookId as SportId,
			dateadd(m, datediff(m, 0, @CurrentDate), 0) as Winlostdate, 
			0 as QualifiedMember,
			0 as ActivePlayer,
			isnull(sum(case bettype when 22001 then (b.winlost-abs(b.actual_stake)) * e.ActualRate2 else 0 end),0) as Deposit,
			0 as Withdrawal,
			sum(case when bettype < 19000 then isnull(abs(stake) * e.ActualRate2, 0) else 0 end) as Turnover,
			isnull(sum(case when bettype < 19000 and ruben=1 then (winlost-abs(actual_stake)+playercomm) * e.ActualRate2 else 0 end),0) as WinLost,
			0 as Commission								
		 FROM bodb02.dbo.bettrans b with(nolock)	
			inner join MemberInfo m with(nolock) on b.CustId = m.IBCCustId and m.AffId = @AffId and m.IsRemoved = 0								   						
			inner join Exchange_Current e with (nolock) on e.exchangeid=b.currency 		
		 
		 WHERE b.Winlostdate = @CurrentDate
			   and (bettype<19000 or bettype in (22001,22004,22002,22003,21001, 21002, 21003, 21004, 21005, 22005))
			   and bettype not in (31,32,33,41,42,43)
			   and bettype not between 71 and 120 --Not include Casino and Number Game
			   and StatusID not in (101, 102, 103, 121,1)

		union all--Get commission and qualified members in previous month and current month
		
		select @SportId as SportId,
			dateadd(m, datediff(m, 0, Winlostdate), 0),
			0 as QualifiedMember,
			count(distinct IBCCustID) as ActivePlayer,
			0 as Deposit,
			0 as Withdrawal,
			0 as Turnover,			
			0 as WinLost,
			0 as Commission
		from Memberdaily nolock
		where AffId = @AffId
			and winlostdate between @FromDate and @CurrentDate 
			and (isnull(TurnOver,0) > 0 or isnull(Deposit,0) > 0)
			and SportType = @SportId
		group by dateadd(m, datediff(m, 0, Winlostdate), 0)*/
		
	) as t
where SportId = @SportId
group by dateadd(m, datediff(m, 0, Winlostdate), 0)

GO
GRANT EXECUTE ON [dbo].[Aff_PerformanceReportByAff] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PerformanceReportByAff] TO [VNTeam] 
GO