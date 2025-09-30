Alter Procedure [Aff_AffiliateStatisticsDetail]
	@AffId int,
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get statistics report detail for affiliate.
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateStatisticsDetail]
Revisions:
    
Param's Explanation:
	• @AffId Affiliate Id
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date of Affiliate,
*/
Set Nocount On	
--Get all date from all related tables
Create table #Temp (Date smalldatetime)

if @IsGetAll = 1
BEGIN
	--From RegisteredDate Column
	insert into #Temp(Date)
	Select dateadd(d, 0, datediff(d, 0, RegisteredDate)) 
	from MemberInfo (nolock)
	where AffID=@AffID and IsRemoved=0
	group by dateadd(d, 0, datediff(d, 0, RegisteredDate))

	insert into #Temp(Date)
	Select dateadd(d, 0, datediff(d, 0, CreatedDate)) 
	from MemberInfo (nolock)
	where AffID=@AffID  and IsRemoved=0
		and CreatedDate is not null and dateadd(d, 0, datediff(d, 0, CreatedDate)) not in (Select Date from #Temp with (nolock))
	group by dateadd(d, 0, datediff(d, 0, CreatedDate))

	insert into #Temp(Date)
	Select distinct winlostdate	
	From  MemberDaily md with(nolock) 
				inner join MemberInfo mi with (nolock) on mi.username=md.username 				
			where Turnover > 0 and IsRemoved=0 and mi.AffID=@AffID		
			and winlostdate not in (Select Date from #Temp with (nolock))
END
ELSE
BEGIN
	Select @Fromdate = dateadd(d, datediff(d, 0, @Fromdate), 0)
	Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
    insert into #Temp(Date)
	Select dateadd(d, 0, datediff(d, 0, RegisteredDate)) 
	from MemberInfo (nolock)
	where AffID=@AffID and username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
			and RegisteredDate between @FromDate and @ToDate	
	group by dateadd(d, 0, datediff(d, 0, RegisteredDate))

	insert into #Temp(Date)
	Select dateadd(d, 0, datediff(d, 0, CreatedDate)) 
	from MemberInfo (nolock)
	where AffID=@AffID  and username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
	and CreatedDate is not null and dateadd(d, 0, datediff(d, 0, CreatedDate)) not in (Select Date from #Temp with (nolock))
		  and CreatedDate between @FromDate and @ToDate
	group by dateadd(d, 0, datediff(d, 0, CreatedDate))
    
	insert into #Temp(Date)
	Select distinct winlostdate	
			From  MemberDaily md with(nolock) 
				inner join MemberInfo mi with (nolock) on mi.username=md.username 				
			where Turnover > 0 and mi.AffID=@AffID and md.WinlostDate between @FromDate and @ToDate
					--and mi.CreatedDate between @FromDate and @ToDate
					and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
				  and winlostdate not in (Select Date from #Temp with (nolock))

END

select @NRows=count(1)    
FROM  #Temp with (nolock)  

if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(date smalldatetime, Active int, Dormant int,Total int , TotalRegistered int)

insert into @TempAff(date)
select date
from  
	(select ROW_NUMBER() OVER(ORDER BY date) AS TheCount,  
		date
	from #Temp with (nolock)    		
	)m 
where m.TheCount between @RowStart and @RowEnd   

drop table #Temp

update t
	set t.Total=isnull(a.Total,0),
		t.TotalRegistered=isnull(a.TotalRegistered,0),
		t.Active=isnull(b.Active,0),
		t.Dormant=isnull(a.Total,0)-isnull(b.Active,0)
	from  @TempAff t	
	left join  	
	(
		SELECT r.Date,
			sum(case when datediff(d,r.date,d.registeredDate)=0 then 1 else 0 end ) as TotalRegistered,
			sum(case when CreatedDate is not null and datediff(d,r.date,d.CreatedDate)=0 then 1 else 0 end) as Total		
		FROM @TempAff r
			inner join MemberInfo d WITH(NOLOCK) on datediff(d,r.date,d.registeredDate)=0 or datediff(d,r.date,d.CreatedDate)=0
		where d.username not in (Select username from MemberRemoval (nolock) where datediff(d,RemovedDate,r.Date)=0 )	
			  and d.AffID=@AffID 	
		group by r.Date

	) a on a.Date = t.Date
   left join
	(
		Select r.date,
			Count(Distinct md.username) as Active		
		From  @TempAff r
			inner join MemberDaily md with(nolock) on md.WinlostDate=r.date
			inner join MemberInfo mi with (nolock) on mi.username=md.username 				
		where Turnover > 0 and
			(
				(md.WinlostDate between @FromDate and @ToDate
				--and mi.CreatedDate between @FromDate and @ToDate
				--and mi.CreatedDate is not null
				--and mi.RegisteredDate between @FromDate and @ToDate	
				) 
				or @IsGetAll = 1
			)
			and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
			and mi.AffID = @AffID
		group by r.date
	)b on b.Date = t.Date

Select * from @TempAff 

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatisticsDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatisticsDetail] TO [VNTeam] 