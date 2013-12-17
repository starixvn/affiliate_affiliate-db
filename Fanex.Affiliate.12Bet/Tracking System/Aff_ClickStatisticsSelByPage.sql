ALTER PROCEDURE [dbo].[Aff_ClickStatisticsSelByPage]  
	@AffID int,  
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@SportCode varchar(50) = null,
	@LanguageCode varchar(10) = null
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
	return

Declare @Result as table(SportCode varchar(50), LanguageCode varchar(10), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatistics1Sum)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
		, @FromDate = convert(varchar(10), @FromDate,120)

if (@LastDateSum < @FromDate)--get from main table
Begin
	insert into @Result
	Select 
		SportCode,
		LanguageCode,
		sum(TotalClick) as TotalClick,
		Sum(UniqueClick) as UniqueClick,
		sum(Signups) as Signups,
		sum(FDM) as FDM
	From(
		Select 
			SportCode,
			LanguageCode,
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick,
			sum(case when status > 0 then 1 else 0 end) as Signups,
			sum(case when status = 2 then 1 else 0 end) as FDM
		from ClickStatistics1 with(nolock) 
		where [Date] between @FromDate and @ToDate
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode, [Date]--[Date] in condition to calculate unique click
		) as tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	Select 
		SportCode,
		LanguageCode,
		sum(TotalClick) as TotalClick,
		sum(UniqueClick) as UniqueClick,
		sum(TotalSignup) as Signups,
		sum(TotalDeposit) as FDM
	from ClickStatistics1Sum with(nolock) 
	where [Date] between @FromDate and @ToDate
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode
End
else--@fromdate < @LastDateSum < @ToDate
Begin
	insert into @Result
	select SportCode,
			LanguageCode,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			SportCode,
			LanguageCode,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(TotalSignup) as Signups,
			sum(TotalDeposit) as FDM
		from ClickStatistics1Sum with(nolock) 
		where [Date] between @FromDate and @LastDateSum
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode

		Union All

		Select 
			SportCode,
			LanguageCode,
			sum(1) as TotalClick,
			count(distinct IP) as UniqueClick,
			sum(case when status > 0 then 1 else 0 end) as TotalSignup,
			sum(case when status = 2 then 1 else 0 end) as TotalDeposit
		from ClickStatistics1 with(nolock) 
		where [Date] between @LastDateSum and @ToDate
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode, [Date]
		) tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode

End

Select * from @Result

GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsSelByPage] TO [vnteam]
GO