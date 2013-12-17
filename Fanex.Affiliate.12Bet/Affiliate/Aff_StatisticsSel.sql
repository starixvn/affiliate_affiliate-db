ALTER PROCEDURE [dbo].[Aff_StatisticsSel]
	@AffID int,
	@MonthDate smalldatetime,
	@TotalQualifiedMembers int OUTPUT,
	@TotalQualifiedCasino int = 0 OUTPUT,	
	@TotalQualifiedMembersHR int OUTPUT,	
	@TotalActivePlayer int OUTPUT,
	@TotalPlayerDepUp int OUTPUT,
	@NewSignUpDep int OUTPUT,	
	@BalBroughtforward money = 0 OUTPUT,
	@TotalDeposit money OUTPUT,
	@TotalDepositUp money OUTPUT,
	@TotalTurnover money OUTPUT,
	@TotalTurnoverUp money OUTPUT,
	@TotalWinlostUp money OUTPUT,
	@TotalWinlost money OUTPUT,
	@TotalUniqueClicks int = 0 OUTPUT,
	@TotalClicks int = 0 OUTPUT,
	@TotalUniqueClicksBySite int = 0 OUTPUT,
	@TotalClicksBySite int = 0 OUTPUT
AS

/*Created: 20090325@VinhTrinh
Task : Get statistics for affiliate
DB: DB052.Affiliate_12BET
Original : [Aff_CustomerSelStatistics]
Revisions:
	- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).
	- 20090827@DungTong: Convert to new DB version
	- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"
	- 20101228@Henry: change bettype to new range
	- 20120507@Johnny: Get Casino qualified Active players
	- 20120606@Peter : Exclude waiting tickets 
Param's Explanation:
• @AffID : Affiliate custid
• @MonthDate : Date search(format:first day of the month).
• @TotalActivePlayer : Get Active player in Month
• @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system
• @NewSignUpDep : Get new signups of the month
• @TotalDeposit : total deposit money for month search
• @TotalDepositUp money OUTPUT,--total deposit money up to now
• @TotalTurnover money OUTPUT,--total turnover money up to now
*/

SET NOCOUNT ON



declare @MaxTransDate smalldatetime, @FromDate smalldatetime, @CurrentDate smalldatetime, @PreviousDate smalldatetime
	, @SportsBookID int, @HorseRacingID int,@CasinoID int, @SPTurnover money, @HRTurnover money, @CasinoTurnover money, @CasinoDeposit money

select @SportsBookID = dbo.Aff_GetSportID('SportsBook'), @HorseRacingID = dbo.Aff_GetSportID('Horse Racing'),@CasinoID=dbo.Aff_GetSportID('Casino')

select @SPTurnover = QMTurnOver from Sporttype with (nolock) where SportID = @SportsBookID
select @HRTurnover = QMTurnOver from Sporttype with (nolock) where SportID = @HorseRacingID
select @CasinoTurnover = QMTurnOver, @CasinoDeposit = QMDeposit from Sporttype with (nolock) where SportID = @CasinoID

select @CurrentDate=convert(varchar(10),current_timestamp,120), @PreviousDate=dateadd(d, -1, @CurrentDate)
select @MaxTransDate = max(WinlostDate) from AffCommission with(nolock)
select @FromDate = dateadd(d, 1, @MaxTransDate)     

select @NewSignUpDep = Count(*)
from MemberInfo m with (nolock)
where m.AffId = @AffId 	
	and datediff(m, CreatedDate, @MonthDate) = 0
	and m.IBCCustId not in (select IBCCustId From MemberRemoval with(nolock) where datediff(m, RemovedDate, @MonthDate) = 0)	

select --If member is created and removed in the same month, he/she will not be counted.
	@TotalPlayerDepUp = Count(*)
from MemberInfo m with (nolock)
where m.AffId = @AffId 
	and IsRemoved = 0 
	
	
Declare @TblStatistics as  table(IBCCustID int, Sporttype int, QualifiedMember int, Turnover money, Deposit money, Winlost money, MonthDate smalldatetime)

insert into @TblStatistics
select 0,
	SportId, 
	QualifiedMember, 
	MemberTurnover, 
	MemberDeposit, 
	MemberWinlost,
	WinlostDate
from AffCommission with (nolock)
where AffId = @AffId 
	and WinlostDate <= @MaxTransDate	
Union All
select b.IBCCustID,
	SportType,
	0,
	sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as Turnover,
	sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit,    
	sum((isnull(Winlost,0)) * isnull(AffExRate,1)) as Winlost,
	dateadd(mm, DATEDIFF(m,0,b.WinlostDate), 0)
from MemberDaily b with (nolock) 
	 inner join MemberInfo ci with (nolock) on ci.IBCCustID=b.IBCCustID
where b.AffID=@AffID 
	and b.winlostdate between @FromDate and @PreviousDate--this condition use up index on winlostdate	
group by b.IBCCustID, SportType,
	dateadd(mm, DATEDIFF(m,0,b.winlostdate), 0)
Union All
select 
	ci.IBCCustID, 
	case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end,
	0,
	isnull(sum(case when bettype < 99 then 
				(case when Bettype in (33,43) and liveawayscore = 0 then isnull(stake, 0) / 2 * e.Actualrate2 else isnull(stake, 0) * e.Actualrate2 end)
			else 0 end),0) as Turnover,	
	isnull(sum(case bettype when 22001 then (winlost-actual_stake)* e.Actualrate2 else 0 end),0) as Deposit,
	isnull(sum(case when (bettype < 99 or bettype in (21001, 21002, 21003, 21004, 21005, 22004, 22005)) AND ruben = 1 then (b.Winlost - b.Actual_Stake) * e.actualrate2 else 0 end), 0) as Winlost, 
	convert(varchar(10),current_timestamp,120)
from MemberInfo ci with (nolock)
	inner join bodb02.dbo.bettrans b with (nolock, index=IX_custid_matchid_bettype) on b.custid = ci.IBCCustID
	INNER JOIN Exchange_Current e with (nolock) on ci.currency = e.exchangeid
where b.winlostdate=@CurrentDate
	and ci.AffID=@AffID
	and ci.IsRemoved = 0
	AND (Bettype < 99  or bettype in (21001, 21002, 21003, 21004, 21005, 22001, 22002 ,22003, 22004, 22005))		
	--AND bettype not in (71,72,73,74,75,76,77,78,79)
	and bettype not between 71 and 120
	and StatusID not in (101, 102, 103, 121,1) 
	--and status not in ('VOID', 'REJECT', 'REFUND','DONE','WAITING')	
Group by ci.IBCCustID, case when bettype in (31,32,33,41,42,43) then @HorseRacingID else @SportsBookID end

--Calculate total up to now
select @TotalWinlostUp = Sum(Winlost)
	, @TotalTurnoverUp = Sum(Turnover)
	, @TotalDepositUp = Sum(case when Sporttype = @SportsBookID then Deposit else 0 end)
from @TblStatistics
--calculate month search
select @TotalWinlost = Sum(Winlost)
	, @TotalTurnover = Sum(Turnover)
	, @TotalDeposit = Sum(case when Sporttype = @SportsBookID then Deposit else 0 end)
from @TblStatistics
where DATEDIFF(m, MonthDate, @MonthDate) = 0
	
--Calculate for ActivePlayer and Qualified players
If @MonthDate > @MaxTransDate
Begin
	select @TotalActivePlayer = count(IBCCustID)
	from (select distinct IBCCustID--Get from table existed 
		from @TblStatistics
		where DATEDIFF(m, MonthDate, @MonthDate) = 0
		group by IBCCustId
		Having sum(isnull(TurnOver,0)) > 0 or sum(isnull(Deposit,0)) > 0
		) a
		
	select @TotalQualifiedMembers = count(IBCCustID)
	from (select distinct IBCCustID
		from @TblStatistics p
		where datediff(m, MonthDate, @MonthDate) = 0
			and Sporttype = @SportsBookID
		group by IBCCustID
		having sum(Turnover) >= @SPTurnover) a
		
	select @TotalQualifiedMembersHR = count(IBCCustID)
	from (select distinct IBCCustID
		from @TblStatistics p
		where datediff(m, MonthDate, @MonthDate) = 0
			and Sporttype = @HorseRacingID
		group by IBCCustID
		having sum(Turnover) >= @HRTurnover) a	

	select @TotalQualifiedCasino = count(IBCCustID)
	from (select distinct IBCCustID
		from @TblStatistics p
		where datediff(m, MonthDate, @MonthDate) = 0
			and Sporttype = @CasinoID
		group by IBCCustID
		having sum(Turnover) >= @CasinoTurnover and SUM(Deposit) >= @CasinoDeposit) a	

End
Else--Get Data in AffCommission
Begin
	Declare @FirstDate smalldatetime, @LastDate smallDatetime	
	select @FirstDate = dateadd(m, datediff(m, 0, @MonthDate), 0)
		, @LastDate = dateadd(d, -1, dateadd(m, datediff(m, 0, @MonthDate) + 1, 0))
		
	
	select @TotalActivePlayer = count(*)
	from (select distinct IBCCustId--Get from Memberdaily
		from MemberDaily b with (nolock) 		 
		where b.AffID=@AffID 
			and b.winlostdate between @FirstDate and @LastDate--this condition use up index on winlostdate	
		group by IBCCustId
		Having sum(isnull(TurnOver,0)) > 0 or sum(isnull(Deposit,0)) > 0
		) a
	
	select @TotalQualifiedMembers = QualifiedMember
	from @TblStatistics
	where datediff(m, MonthDate, @MonthDate) = 0
		and Sporttype = @SportsBookID
		
	select @TotalQualifiedMembersHR = QualifiedMember
	from @TblStatistics
	where datediff(m, MonthDate, @MonthDate) = 0
		and Sporttype = @HorseRacingID

  select @TotalQualifiedCasino = QualifiedMember
	from @TblStatistics
	where datediff(m, MonthDate, @MonthDate) = 0
		and Sporttype = @CasinoID

End
--End Calculate for Month Search	
--Get tracking information
if(datediff(mm,@MonthDate,current_timestamp)=0)
begin
	select @TotalClicks=count(1)
	from ClickStatistics s (nolock)
	 inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID and a.AffID=@AffID
	where s.date >= @MonthDate

	select @TotalUniqueClicks=count(distinct s.IP)
	from ClickStatistics s (nolock)
	 inner join TrackingCode a (nolock)  on a.TrackingID=s.TrackingID and a.AffID=@AffID
	where s.date >= @MonthDate
	--group by a.AffiliateID,month(s.Date),year(s.Date)
end
else
begin
	select @TotalClicks=TotalClick,@TotalUniqueClicks=UniqueClick
	from ClickStatisticsSum (nolock)
	where AffID=@AffID
			   and TrackingID=0
			   and IsForMonth=1 
			   and datediff(mm,@MonthDate,[date])=0
end

--Tracking statistics for new link
declare @ToDate smalldatetime
select @ToDate = dateadd(d, -1, dateadd(mm, 1, @MonthDate))

Select @TotalClicksBySite = TotalClicks,
	@TotalUniqueClicksBySite = UniqueClicks
from [dbo].[Aff_GetClickStatisticsNew_Func](@AffId, @MonthDate, @Todate)

--get Balance broughtForward
select @BalBroughtforward = isnull(dbo.Aff_GetAffBalance(@AffID), 0)
		
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_StatisticsSel] TO [VNTeam]