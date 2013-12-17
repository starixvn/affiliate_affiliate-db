ALTER Procedure [dbo].[AffAdmin_ClickStatisticsSelBySite]    
	@AffID int,    
	@FromDate smalldatetime,  
	@ToDate smalldatetime,  
	@TotalClicks int = 0 output,  
	@UniqueClicks int = 0 output  
AS    
/*    
Created: 20111005@Johnny    
Task :   Report click statistics by Referrer site  
DB: DB052.Affiliate_12BET    
Original:    
    
Revisions:    
-   
*/    
  
SET NOCOUNT ON    
  
Declare @LastDateSum smalldatetime  
if(@FromDate > @ToDate)  
	return  
  
Declare @Result as table(DomainReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)  
  
select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)  
  
select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))  
	, @FromDate = convert(varchar(10), @FromDate,120)  
  
if (@LastDateSum < @FromDate)--get from main table  
Begin  
insert into @Result  
select DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(Signups) as Signups,  
	sum(FDM) as FDM  
from   
	(  
	Select   
		DomainReferrer,  
		sum(ClickCount) as TotalClick,  
		count(distinct IP) as UniqueClick,  
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM 
	from ClickStatistics c with(nolock)   
		left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 
			where AffId = @AffID
			group by ClickId
			) as m on c.ClickId = m.ClickId
	where [Date] between @FromDate and @ToDate  
		and c.AffId = @AffID  
	group by DomainReferrer, [Date]  
	) as t  
group by DomainReferrer  
End  
else if (@LastDateSum > @ToDate)--get from summary table  
Begin  
insert into @Result  
Select   
	DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(TotalSignup) as Signups,  
	sum(TotalDeposit) as FDM  
from ClickStatisticsSum with(nolock)   
where [Date] between @FromDate and @ToDate  
	and AffId = @AffID  
group by DomainReferrer  
End  
else--@fromdate < @LastDateSum < @ToDate  
Begin  
insert into @Result  
select DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(Signups) as Signups,  
	sum(FDM) as FDM  
from   
	(  
	Select   
		DomainReferrer,  
		sum(TotalClick) as TotalClick,  
		sum(UniqueClick) as UniqueClick,  
		sum(TotalSignup) as Signups,  
		sum(TotalDeposit) as FDM  
	from ClickStatisticsSum with(nolock)   
	where [Date] between @FromDate and @LastDateSum  
		and AffId = @AffID  
	group by DomainReferrer  
  
	Union All  
  
	Select   
		DomainReferrer,  
		sum(ClickCount) as TotalClick,  
		count(distinct IP) as UniqueClick,  
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM 
	from ClickStatistics c with(nolock)   
			left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 
			where AffId = @AffID
			group by ClickId
			) as m on c.ClickId = m.ClickId
	where [Date] between @LastDateSum and @ToDate  
		and c.AffId = @AffID  
	group by DomainReferrer, [Date]  
	) tmp  
group by DomainReferrer  
  
End  
  
Select * from @Result  
  
select @TotalClicks = SUM(TotalClick)  
    , @UniqueClicks = SUM(UniqueClick)  
from @Result


