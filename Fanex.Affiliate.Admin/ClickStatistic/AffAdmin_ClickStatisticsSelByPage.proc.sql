ALTER Procedure [dbo].[AffAdmin_ClickStatisticsSelByPage]  
	@AffID int,  
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@SportCode varchar(200) = null,
	@LanguageCode varchar(100) = null
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
	return

DECLARE @SportCodeTable TABLE (SportCode varchar(20))
INSERT INTO @SportCodeTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @SportCode, ',' )

DECLARE @LanguageCodeTable TABLE (LanguageCode varchar(20))
INSERT INTO @LanguageCodeTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @LanguageCode, ',' )

Declare @Result as table(SportCode varchar(50), LanguageCode varchar(10), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)

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
		SUM(Signups) as Signups,
		SUM(FDM) as  FDM
	From(
		Select 
			c.SportCode,
			c.LanguageCode,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
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
		group by c.SportCode, c.LanguageCode, [Date]--[Date] in condition to calculate unique click
		) as tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	Select 
		c.SportCode,
		c.LanguageCode,
		sum(TotalClick) as TotalClick,
		sum(UniqueClick) as UniqueClick,
		sum(TotalSignup) as Signups,
		sum(TotalDeposit) as FDM
	from ClickStatisticsSum c with(nolock)  
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
	where [Date] between @FromDate and @ToDate
			and AffId = @AffID
	group by c.SportCode, c.LanguageCode
	order by c.SportCode, c.LanguageCode
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
			c.SportCode,
			c.LanguageCode,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(TotalSignup) as Signups,
			sum(TotalDeposit) as FDM
		from ClickStatisticsSum c with(nolock) 
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
		where [Date] between @FromDate and @LastDateSum
			and AffId = @AffID
		group by c.SportCode, c.LanguageCode

		Union All

		Select 
			c.SportCode,
			c.LanguageCode,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			INNER JOIN @SportCodeTable s on c.SportCode = s.SportCode
			INNER JOIN @LanguageCodeTable l on c.LanguageCode = l.LanguageCode
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
		group by c.SportCode, c.LanguageCode, [Date]
		) tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode

End

Select * from @Result

GO
GRANT EXECUTE ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ClickStatisticsSelByPage] TO [vnteam]