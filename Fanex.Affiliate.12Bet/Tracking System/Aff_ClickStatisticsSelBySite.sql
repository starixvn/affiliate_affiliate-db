ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelBySite]  
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

select @LastDateSum = (select MAX(Date) from ClickStatistics1Sum)

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
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick,
			sum(case when status > 0 then 1 else 0 end) as Signups,
			sum(case when status = 2 then 1 else 0 end) as FDM
		from ClickStatistics1 with(nolock) 
		where [Date] between @FromDate and @ToDate
			and AffId = @AffID
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
	from ClickStatistics1Sum with(nolock) 
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
		from ClickStatistics1Sum with(nolock) 
		where [Date] between @FromDate and @LastDateSum
			and AffId = @AffID
		group by DomainReferrer

		Union All

		Select 
			DomainReferrer,
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick,
			sum(case when status > 0 then 1 else 0 end) as TotalSignup,
			sum(case when status = 2 then 1 else 0 end) as TotalDeposit
		from ClickStatistics1 with(nolock) 
		where [Date] between @LastDateSum and @ToDate
			and AffId = @AffID
		group by DomainReferrer, [Date]
		) tmp
	group by DomainReferrer

End

Select * from @Result

select @TotalClicks = SUM(TotalClick)
	   , @UniqueClicks = SUM(UniqueClick)
from @Result
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsSelBySite] TO [vnteam]
GO