ALTER Procedure [dbo].[AffAdmin_StatisticsSel]  
	@AffID int,  
	@MonthDate smalldatetime,
	@TotalActivePlayer int OUTPUT,  
	@TotalPlayerDepUp int OUTPUT,  
	@NewSignUpDep int OUTPUT,  
	@NewSignUp int OUTPUT,  
	@TotalPlayer int OUTPUT,   
	@BalBroughtforward money = 0 OUTPUT,  
	@TotalDeposit money OUTPUT,  
	@TotalDepositUp money OUTPUT,  
	@TotalTurnover money OUTPUT,  
	@TotalTurnoverUp money OUTPUT,  
	@TotalWinlostUp money OUTPUT,  
	@TotalWinlost money OUTPUT,  
	@TotalUniqueClicks int = 0 OUTPUT,  
	@TotalClicks int = 0 OUTPUT 
AS  
  
/*Created: 20090325@VinhTrinh  
Task : Get statistics for affiliate  
DB: DB052.Affiliate_MYM  
Original : [Aff_StatisticsSel]  
Revisions:  
	- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).  
	- 20090827@DungTong: Convert to new DB version  
	- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"  
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
  
SELECT @NewSignUp = sum(case when DATEDIFF(MONTH,@MonthDate,RegisteredDate) = 0 then 1  else 0 end)  
	,@NewSignUpDep = sum(case when CreatedDate is not null and datediff(m, CreatedDate, @MonthDate) = 0  then 1 else 0 end)  
	,@TotalPlayerDepUp=sum(case when  CreatedDate is not null and IsRemoved=0 then 1 else 0 end)   
	,@TotalPlayer=sum(case when IsRemoved=0 then 1 else 0 end)   
FROM MemberInfo WITH(NOLOCK)  
WHERE AffID = @AffID        
	and username not in (select username From MemberRemoval with(nolock) where datediff(m, RemovedDate, @MonthDate) = 0)   
  
create table #TblStatistics (username varchar(30), ProductID int, QualifiedMember int,ActivePlayer int, Turnover money, Deposit money, Winlost money, MonthDate smalldatetime)  

insert into #TblStatistics  
select '',  
	ProductID,   
	QualifiedMember,   
	ActivePlayer,  
	MemberTurnover_aff, --Turnover has been change to AffExRate  
	MemberDeposit_aff, --Deposit has been change to AffExRate  
	MemberWinlost_aff as MemberWinlost,--Winlost has been change to AffExRate  
	WinlostDate  
from AffCommission with (nolock)  
where AffId = @AffId   

declare @MaxTransDate datetime, @FromDate datetime, @CurrentDate datetime, @QMTurnover money  
  
select @QMTurnover=dbo.[Aff_GetQMTurnOver](@AffID,@MonthDate), @CurrentDate= current_timestamp
select @MaxTransDate = max(MonthDate) from #TblStatistics with(nolock)  
if @MaxTransDate is not null  
   select @FromDate = dateadd(d,1,@MaxTransDate)  
else 
      select @FromDate = MIN(WinlostDate) from AffDailySummary(nolock) 
   

insert into #TblStatistics  
  
select ci.username,  
	ProductID,  
	0 as QualifiedMember,  
	0 as ActivePlayer,  
	sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as Turnover,  
	sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit,      
	sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost,  
	dateadd(mm, DATEDIFF(m,0,b.WinlostDate), 0)  
from MemberDaily b with (nolock)   
	inner join MemberInfo ci with (nolock) on ci.username=b.username  
where ci.AffID=@AffID   
	and b.winlostdate between @FromDate and @CurrentDate--this condition use up index on winlostdate      
group by ci.username, ProductID,  
	dateadd(mm, DATEDIFF(m,0,b.winlostdate), 0)  


update #TblStatistics

set QualifiedMember=(case when Turnover>=@QMTurnover then 1 else 0 end)    

where username<>''


Select @TotalWinlostUp = Sum(a.Winlost)  
	, @TotalTurnoverUp = Sum(a.Turnover)  
	, @TotalDepositUp = Sum(a.Deposit)  
	,@TotalWinlost = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Winlost else 0 end)  
	, @TotalTurnover = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Turnover else 0 end)  
	, @TotalDeposit = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Deposit else 0 end)  
	--,@TotalActivePlayer=sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0  then isnull(a.ActivePlayer,0) else 0 end)   

  
From #TblStatistics a with (nolock)  

declare @DateTemp datetime

set @DateTemp=dbo.Date_Only(dbo.Aff_GetLastDayOfMonth(@MonthDate))



if(exists(select top(1) 1 from AffCommission (nolock) where winlostdate=@DateTemp))
BEGIN
 select @TotalActivePlayer=max(ActivePlayer)
 From #TblStatistics a with (nolock)  
 where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username=''
END
else
BEGIN
   select @TotalActivePlayer=count(distinct username)
  From #TblStatistics a with (nolock)  
  where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username<>''
              and (a.Turnover>0 or a.Deposit>0) 
END



  
--Get Click Statistics  
  
select @TotalClicks= sum(TotalClick),  @TotalUniqueClicks=sum(UniqueClick)  
FROM  
(  
	select sum(TotalClick) as TotalClick,Sum(UniqueClick) as UniqueClick  
	from ClickStatisticsSum (nolock)  
	where AffID=@AffID              
		and datediff(mm,@MonthDate,[date])=0  
	
	union all  

	select sum(ClickCount) as TotalClick,count(distinct s.IP) as UniqueClick  
	from ClickStatistics s (nolock)   
	where datediff(mm,@MonthDate,s.date)=0 and s.AffID=@AffID  
	group by dbo.Date_Only(Date),DomainReferrer, SportCode, LanguageCode  
) t  
  
select @BalBroughtforward = isnull(dbo.Aff_GetAffBalance(@AffID), 0)     


if(DATEDIFF(m, current_timestamp, @MonthDate) >0 )
begin
		  Select p.ProductID,p.ProductName,0  as TotalQualifiedMembers 
		  From Product p  with (nolock)  
		  where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,current_timestamp) >0   
		  order by p.ProductID
end
else
begin
		Select p.ProductID,p.ProductName,isnull(t.TotalQualifiedMembers,0)  as TotalQualifiedMembers 
		 From Product p  with (nolock)  
		left join 
		(
		   select a.ProductID, sum(a.QualifiedMember) as TotalQualifiedMembers
		   from #TblStatistics a (nolock)  
		   where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and [dbo].[Aff_IsProductInGroupOfAff](@AffID,a.ProductID ,@MonthDate) >0
		   group by a.ProductID

		) t on t.ProductID=p.ProductID
		where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,@MonthDate) >0   
		  order by p.ProductID

end

Drop table #TblStatistics