ALTER PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate]
	@date smalldatetime = null
AS
/*
  Task to summary Click Statistics daily
  Writer : Johnny
  Date : 2012/01/09
  DB: DB052.Affiliate_12BET
	
*/
 SET NOCOUNT ON


select @date = convert(varchar(10), ISNULL(@date, dateAdd(d, -30, current_timestamp)), 120)

if(exists (select 1 from ClickStatisticsSum (nolock) where datediff(d,@date,[Date])=0))
 begin
   return
 end 

/* 
--Store Total number of deposit user
Declare @TmpDeposit as table(AffId int, TotalDeposit int)
insert into @TmpDeposit(AffId, TotalDeposit)
Select AffId, Sum(1) as TotalDeposit
From MemberInfo nolock
where datediff(d, CreatedDate, @date) = 0
Group by AffId 
 */

 --Summary for Daily by Domain and Date
insert into ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
select  c.AffID,
		DomainReferrer,
		@date as [Date],
		SportCode,
		LanguageCode,
		sum(ClickCount) as TotalClick,
		count(distinct IP) as UniqueClick,
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM
from ClickStatistics c with (nolock)
	left join 
		(Select ClickId, 
			SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
			SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
		from MemberInfo m with (nolock) 		
		group by ClickId
		) as m on c.ClickId = m.ClickId
where datediff(d, @date, [date])=0
group by c.AffID, DomainReferrer, SportCode, LanguageCode


insert into ClickStatistics_bk
select * from ClickStatistics
where datediff(d, @date, [date])=0

delete ClickStatistics
where datediff(d, @date, [date])=0

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate] TO [vnteam]
