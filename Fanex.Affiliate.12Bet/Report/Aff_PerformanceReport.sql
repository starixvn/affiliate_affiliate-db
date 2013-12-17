---Lưu ý : Get Code mới nhất

set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_PerformanceReport]
	@UserName varchar(50) = null,
	@Language varchar(11) = null,
	@FromDate datetime,
	@ToDate datetime,
	@SortBy varchar(20) = 'Member',
	@SportId int = 0,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT   
AS
/*
Created: @VinhTrinh
Task : Show performance report for admin.
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateReport]
Revisions:
		 - 20111031@Peter : Exclude Number Game from Sportsbook commission (bettype from [81-120])
		 - 20120606@Peter : Exclude waiting tickets

Param's Explanation:
	• @UserName Search by username
	• @Language Search by language
	• @FromDate From date
	• @ToDate	To date
	• @SortBy	Sort by field
	If @SortBy=Commission and
	@SportID=0 : View all
	         1: View by Sportsbook
			 3: View by Casino
*/
Set Nocount On

if @FromDate > @ToDate
	return

create table #Result(AffId int primary key, Username varchar(50), QualifiedMembers int, ActivePlayer int, Deposit money, Withdrawal money, Turnover money, Winlost money, Commission money)

Declare @CurrentDate smalldatetime, @LastMonthlydate smalldatetime, @FirstDate smalldatetime, @TmpToDate smallDateTime, @NoComGroupID int

--Assign @ToDate to last date of @ToDate, @FromDate equal 1st of @fromdate
select @CurrentDate = dateadd(d, 0, datediff(d, 0, current_timestamp))
		, @FromDate = dateadd(m, datediff(m, 0, @FromDate), 0)--Assign fromdate to 1st of month of fromdate
		, @ToDate = dateadd(d, -1, dateadd(m, datediff(m, 0, @ToDate) + 1, 0))--Assign todate to last date of month of todate
		, @TmpToDate = @ToDate

if(@ToDate >= @CurrentDate)
Begin
	Select @TmpToDate = DateAdd(d, -1, @CurrentDate)--To Exclude current date for calculating affdaily table
End


select @LastMonthlydate = max(WinlostDate) from AffCommission (nolock)


select @FirstDate = dateadd(d, 1, @LastMonthlydate)

select @UserName = '%' + isnull(@UserName, '') + '%'
select @Language = '%' + isnull(@Language, '') + '%'

select @NoComGroupID=GroupID from CommGroup(nolock) where GroupName='NoCommission'

--Get list aff sastify search condition
insert into #Result(AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission)
select ad.AffId, ad.Username,0,0,0,0,0,0,0
from AffDetail ad with(nolock)
	inner join AffInfo ai with (nolock) on ad.AffId = ai.AffId
where ad.Username like @UserName
	and PreferredLanguage like @Language
	and ai.ApprovedDate < @ToDate
--Exclude all closed affs 
	and (ai.IsClosed=0 or ai.GroupID<>  @NoComGroupID)
	and ai.Status='approved'  
select @NRows=@@ROWCOUNT

DECLARE @RowStart int, @RowEnd int


SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1      



update r

set r.QualifiedMembers=isnull(t.QualifiedMembers,0),
	 r.ActivePlayer=isnull(t.ActivePlayer,0),
	 r.Deposit=isnull( t.Deposit,0),
	 r.Withdrawal=isnull(t.Withdrawal,0),
	 r.Turnover=isnull(t.Turnover,0),
	 r.Winlost=isnull(t.Winlost,0),
	 r.Commission=isnull(t.Commission,0)

from #Result r with (rowlock,updlock)
left join
(
select tmp.AffId
		, tmp.Username
		, Sum(QualifiedMember) as QualifiedMembers
		, Sum(ActivePlayer) as ActivePlayer
		, Sum(MemberDeposit) as Deposit
		, Sum(Withdrawal) as Withdrawal
		, Sum(MemberTurnover) as Turnover
		, Sum(MemberWinlost) as Winlost
		, Sum(Commission) as Commission
from	
	(
		---@sportID in order to exclude bettrans in case for casino commission 
		select @SportId as SportId, a.AffId, a.Username, Sum(ac.QualifiedMember) as QualifiedMember, 0 as ActivePlayer
			 , Sum(ac.MemberDeposit) as MemberDeposit, 0 as Withdrawal, Sum(ac.MemberTurnover) as MemberTurnover
		  , Sum(ac.MemberWinlost) as MemberWinlost, Sum(ac.AffWinlost) as Commission
		from #Result a (nolock)
			inner join AffCommission ac with (nolock) on a.AffId = ac.AffId			
		where ac.WinlostDate between @FromDate and @ToDate
			and SportId = @SportId
		Group by a.AffId, a.Username

		union all
		--Calculate Withdrawal
		select 1 as SportId, a.AffId, a.Username, 0 as QualifiedMember, 0 as ActivePlayer, 0 as MemberDeposit, Sum(isnull(af.Amount, 0)) as Withdrawal, 0 as MemberTurnover, 0 as MemberWinlost, 0 as Commission
		from #Result a (nolock)
			inner join AffTrans af with (nolock) on a.AffId = af.AffId 
		where af.CompletedDate between @FromDate and @ToDate and af.transtype = 202 and af.Status = 'Approved'--For withdrawal 		
		Group by a.AffId, a.Username		
		
		union all

		--Calculate Active player
		select m.SportType as SportId, a.AffId, a.Username, 0 as QualifiedMember, count(distinct IBCCustID) as ActivePlayer, 0 as MemberDeposit, 0 as Withdrawal, 0 as MemberTurnover, 0 as MemberWinlost, 0 as Commission
		from #Result a (nolock)
			inner join memberdaily m with(nolock) on a.AffId = m.AffId
		where WinlostDate between @FromDate and @ToDate
			and (isnull(m.TurnOver,0) > 0 or isnull(m.Deposit,0) > 0)
			and m.SportType = @SportId
		group by m.SportType, a.AffId, a.Username
	) as tmp
where SportId = @SportId
Group by tmp.AffId, tmp.Username

) t on r.AffID=t.AffID;

declare @temp table(AffId int primary key, Username varchar(50), QualifiedMembers int, ActivePlayer int, Deposit money, Withdrawal money, Turnover money, Winlost money, Commission money)

insert into @temp(AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission)

select AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission
from  
		(select ROW_NUMBER() OVER(
						order by (case when @SortBy = 'Member' then QualifiedMembers 
									when @SortBy = 'Deposit' then Deposit 
									when @SortBy = 'Turnover' then Turnover 
									when @SortBy = 'Winlost' then Winlost 
									when @SortBy = 'Commission' then Commission 
									else AffId end) desc
					) AS TheCount,  
			AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission
		from #Result (nolock)
		) m
	where m.TheCount between @RowStart and @RowEnd


drop table #Result

if(DATEDIFF(M,@CurrentDate,@ToDate)>=0)
begin
		update t
			set t.QualifiedMembers=t.QualifiedMembers + coalesce(a.TotalQM,0),
				t.Deposit=t.Deposit + coalesce(a.MemDeposit,0),
				t.Turnover=t.Turnover + coalesce(a.MemTurnover,0),
				t.Winlost=t.Winlost + coalesce(a.MemWinlost,0),                
				t.Commission=t.Commission + coalesce(a.Amount,0)           
			from   @temp as t 
			  CROSS APPLY [dbo].[Aff_CommissionForCurrentMonth](t.AffID) as a
			where  a.SportID=@SportId
end

declare @Month int, @Year int

select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))
if(datediff(m,@LastMonthlydate,@CurrentDate)>1 and @FromDate = @FirstDate)
begin--For previous month that is not transfered
		
		 update t
			set t.QualifiedMembers=t.QualifiedMembers + coalesce(a.TotalQM,0),
				t.Deposit=t.Deposit + coalesce(a.MemDeposit,0),
				t.Turnover=t.Turnover + coalesce(a.MemTurnover,0),
				t.Winlost=t.Winlost + coalesce(a.MemWinlost,0),                
				t.Commission=t.Commission + coalesce(a.Amount,0)           
			from   @temp as t 
			  CROSS APPLY [dbo].[Aff_CommissionForMonth](t.AffID,@Month,@Year) as a
			where  a.SportID=@SportId
end

select * from
(
select ROW_NUMBER() OVER(
						order by (case when @SortBy = 'Member' then QualifiedMembers 
									when @SortBy = 'Deposit' then Deposit 
									when @SortBy = 'Turnover' then Turnover 
									when @SortBy = 'Winlost' then Winlost 
									when @SortBy = 'Commission'  then Commission 
									else AffId end) desc
					) AS TheCount,  
			AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission
 from @Temp
) t 
order by TheCount,AffID


/*
-- if include range of current date and month that is not transfered then we will calculate commission for the result set
--no need to sort by commission
select t.Thecount,AffId, Username, QualifiedMembers, ActivePlayer, Deposit, Withdrawal, Turnover, Winlost, Commission
from temp as t
left join 
( select t1.AfffID, c.TotalQM,
			   c.MemDeposit,			  
			   c.MemTurnOver,
			   c.MemWinlost,
			   c.Amount
	   from temp as t1 
	   outer apply Aff_CommissionForCurrentMonth(t1.AffId) as c
  where and c.SportID=@SportId
  
  union all
  select t2.AfffID, c1.TotalQM,
			   c1.MemDeposit,			  
			   c1.MemTurnOver,
			   c1.MemWinlost,
			   c1.Amount
	   from temp as t2 
	   outer apply Aff_CommissionForMonth(t1.AffId,MONTH(),YEAR()) as c1
  where DATEDIFF(M,@CurrentDate,@ToDate)>=0 and c1.SportID=@SportId

  ) c on t.AffId=c.AffID
*/




GO
GRANT EXECUTE ON [dbo].[Aff_PerformanceReport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PerformanceReport] TO [VNTeam] 
GO