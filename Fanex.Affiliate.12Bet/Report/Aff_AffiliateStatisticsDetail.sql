Alter Procedure [Aff_AffiliateStatisticsDetail]
	@AffId int,
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit
AS
/*
Created: @VinhTrinh
Task : Get statistics report detail for affiliate.
DB: DB052.Affiliate_12BET
Original: [Aff_CustomerSelDetailsByAff]
Revisions:
	
Param's Explanation:
	• @AffId Affiliate Id
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date of Affiliate,
*/
Set Nocount On	

--Calculate tracking statistics
Declare @Tracking as Table (TrackingDate smallDatetime, TotalClick int, UniqueClick int)

if @IsGetAll = 1
Begin
	insert into @Tracking
	select Date, sum(1) as TotalClick, count(distinct s.IP) as UniqueClick
	from ClickStatistics s (nolock)
	where IP <> '' and datediff(mm, current_timestamp, s.date)=0
		and trackingid in (
			select trackingid 
			from TrackingCode (nolock) 
			where AffID=@AffID
			) 
	group by s.Date
   
	Union all
	
	select Date, TotalClick, UniqueClick
	from ClickStatisticsSum s (nolock)
	where AffID=@AffID 
	   and TrackingID=0
	   and IsForMonth=0 
End
else
Begin
	
	Declare @FirstDateOfThisMonth smalldatetime, @TmpFDate smalldatetime, @TmpTDate smalldatetime
	
	select @FirstDateOfThisMonth = dateadd(m, datediff(m, 0, current_timestamp), 0),
		@TmpFDate = case when @Fromdate <= @FirstDateOfThisMonth then @FirstDateOfThisMonth else @Fromdate end,
		@TmpTDate = case when @ToDate >= @FirstDateOfThisMonth then dateadd(d, -1, @FirstDateOfThisMonth) else @ToDate end
	
	insert into @Tracking 
	select Date, sum(1) as TotalClick, count(distinct s.IP) as UniqueClick--Current month
	from ClickStatistics s (nolock)
	where IP <> '' 
		and s.date between @TmpFDate and @ToDate
		and trackingid in (
			select trackingid 
			from TrackingCode (nolock) 
			where AffID=@AffID
			) 
	group by s.Date
   
	Union all
	
	select Date, TotalClick, UniqueClick--Old month
	from ClickStatisticsSum s (nolock)
	where AffID=@AffID 
	   and TrackingID=0
	   and IsForMonth=0
	   and s.date between @FromDate and @TmpTDate 
End


----Get data----
if @IsGetAll = 1
Begin
	select datediff(d, 0, CreatedDate) as ForeignKey,
		CreatedDate,
		Sum(Active) as Active,
		Sum(Total) as Total,
		Sum(TotalClick) as TotalClick,
		Sum(UniqueClick) as UniqueClick
	From
	(	
		select convert(varchar(10), CreatedDate, 120) as CreatedDate,
			0 as Active,
			count(distinct IBCCustId) as Total,
			0 as TotalClick,
			0 as UniqueClick
		from MemberInfo with (nolock)
		where AffId = @AffId
		group by convert(varchar(10), CreatedDate, 120)
		
		Union All
		
		select WinlostDate as CreatedDate,
			count(distinct m.IBCCustId) as Active,
			0 as Total,
			0 as TotalClick,
			0 as UniqueClick
		from MemberDaily m with (nolock)
			inner join
			(
				select IBCCustId,
					convert(varchar(10), CreatedDate, 120) as CreatedDate
				from MemberInfo with (nolock) 
				where AffId = @AffId
			)as tmp on m.IBCCustId = tmp.IBCCustId and m.WinlostDate = tmp.CreatedDate		
		where AffID = @AffId
			and turnover > 0
		group by WinlostDate
		
		Union All
		
		select TrackingDate,
			0,
			0,
			TotalClick,
			UniqueClick
		from @Tracking
		) tmp
	Group by datediff(d, 0, CreatedDate), CreatedDate
End
Else
Begin	
	Select @ToDate = dateadd(s, -60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
	
	select datediff(d, 0, CreatedDate) as ForeignKey, CreatedDate,
		Sum(Active) as Active,
		Sum(Total) as Total,
		Sum(TotalClick) as TotalClick,
		Sum(UniqueClick) as UniqueClick
	From
		(
		select convert(varchar(10), CreatedDate, 120) as CreatedDate,
			0 as Active,
			count(distinct m.IBCCustId) as Total,
			0 as TotalClick,
			0 as UniqueClick
		from MemberInfo m with (nolock)
		where AffID = @AffId
			and CreatedDate Between @Fromdate and @Todate	
		group by convert(varchar(10), CreatedDate, 120)
		
		Union All
		
		select WinlostDate as CreatedDate,
			count(distinct m.IBCCustId) as Active,
			0 as Total,
			0 as TotalClick,
			0 as UniqueClick
		from MemberDaily m with (nolock)
			inner join 
			(
				select IBCCustId,
					convert(varchar(10), CreatedDate, 120) as CreatedDate
				from MemberInfo with (nolock) 
				where AffId = @AffId and CreatedDate Between @Fromdate and @Todate
			)as tmp on m.IBCCustId = tmp.IBCCustId and m.WinlostDate = tmp.CreatedDate
		where AffID = @AffId
			and turnover > 0
			and WinlostDate Between @Fromdate and @Todate
		group by WinlostDate		
		
		Union All
		
		select TrackingDate,
			0,
			0,
			TotalClick,
			UniqueClick
		from @Tracking
		) tmp
	Group by datediff(d, 0, CreatedDate), CreatedDate

End

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatisticsDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatisticsDetail] TO [VNTeam] 