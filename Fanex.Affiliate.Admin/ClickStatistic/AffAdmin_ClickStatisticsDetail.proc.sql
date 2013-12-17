ALTER Procedure [dbo].[AffAdmin_ClickStatisticsDetail]  
	@AffID int,  
	@Domain nvarchar(300) = null,
	@SportCode varchar(50) = null,
	@LanguageCode varchar(10) = null,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
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

Declare @Result as table(UrlReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)
		, @FromDate = convert(varchar(10), @FromDate,120)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))

if (@LastDateSum < @FromDate)--get from main table
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
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
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) as t
	group by URLReferrer
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics_bk c with(nolock) 
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
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) as t
	group by URLReferrer
End
else--@fromdate < @LastDateSum < @ToDate
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics_bk c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @FromDate and @LastDateSum
			and c.AffId = @AffID
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]

		Union All

		Select 
			URLReferrer,
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
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) tmp
	group by URLReferrer

End

--Select * from @Result

--count nrows
select @NRows=count(1)
FROM @Result

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	*
FROM(       
	SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY URLReferrer) AS TheCount,
			*
	FROM @Result
	   ) x
 where x.TheCount between @RowStart and @RowEnd


