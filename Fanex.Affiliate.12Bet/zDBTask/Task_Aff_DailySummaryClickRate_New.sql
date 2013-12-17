ALTER PROCEDURE [dbo].[Task_Aff_DailySummaryClickRate_New]
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

if(exists (select 1 from ClickStatistics1Sum (nolock) where datediff(d,@date,[Date])=0))
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
insert into ClickStatistics1Sum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
select  AffID,
		DomainReferrer,
		@date as [Date],
		SportCode,
		LanguageCode,
		sum(1) as TotalClick,
		count(distinct IP) as UniqueClick,
		SUM(case when status > 0 then 1 else 0 end) as TotalSignup,
		SUM(case when status = 2 then 1 else 0 end) as  TotalDeposit
from ClickStatistics1 (nolock)
where datediff(d, @date, [date])=0
group by AffID, DomainReferrer, SportCode, LanguageCode


insert into ClickStatistics1_bk
select * from ClickStatistics1
where datediff(d, @date, [date])=0

delete ClickStatistics1
where datediff(d, @date, [date])=0

GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate_New] TO [vnteam]