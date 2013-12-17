ALTER Procedure [dbo].[Aff_ActiveMemberReport]
	@Fromdate datetime=null,
	@Todate datetime=null,
	@IsGetAll bit=0,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_12BET
Original: [Aff_ActiveMemberReport]
Revisions:
	- Remove TrackingCode table when inner join with ClickstatisticsSum table 
	
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @TotalPages num pages return,
	• @NRows num rows return
*/
Set Nocount On

select @UserName= '%' + Coalesce(@UserName, '') + '%'
Select @ToDate = dateadd(s, -60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE ai.Status='Approved'
	--and ai.IsClosed=0
	and ai.Username like @UserName
	and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
	--and AffType = @AffType
	and (@IsGetAll = 1 or ai.ApprovedDate <= @Todate)

if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
		
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),IsClosed bit)

insert into @TempAff
select m.AffId, m.username,m.IsClosed
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.IsClosed,ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage,ai.IsClosed
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
	where ai.Status = 'Approved'
		--and ai.IsClosed=0
		and ai.Username like @UserName  
		and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		--and AffType = @AffType
		and (@IsGetAll = 1 or ai.ApprovedDate <= @Todate)
	)m 
where m.TheCount between @RowStart and @RowEnd      


Select tmp.AffId,
		tmp.Username,
		tmp.IsClosed,
		Sum(isnull(FDM, 0)) as FDM,
		Sum(isnull(TotalClicks, 0)) as TotalClicks,
		Sum(isnull(TotalUniqueClicks, 0)) as TotalUniqueClicks,
		Sum(isnull(TotalClicks_New, 0)) as TotalClicks_New,
		Sum(isnull(TotalUniqueClicks_New, 0)) as TotalUniqueClicks_New
from 
	@TempAff as tmp left outer join
	(
	Select t.AffId,
			count(distinct isnull(IBCCustID, 0)) as FDM,
			0 as TotalClicks,
			0 as TotalUniqueClicks,
			0 as TotalClicks_New,
			0 as TotalUniqueClicks_New
	From @TempAff as t
		inner join MemberInfo m with (nolock) on t.AffId = m.AffId
	where @IsGetAll = 1 or 
			(
			m.CreatedDate between @FromDate and @ToDate
			and m.IBCCustId not in (select IBCCustId From MemberRemoval nolock where RemovedDate between @FromDate and @ToDate)
			)
	Group by t.AffId

	union all
	--For Caculate Click and unique clicks
	select t.AffId, 
			0 as FDM, 
			sum(1) as TotalClicks, 
			count(distinct s.IP) as TotalUniqueClicks,
			0 as TotalClicks_New,
			0 as TotalUniqueClicks_New
	from @TempAff as t 
		inner join TrackingCode a with (nolock) on a.AffID=t.AffID
		inner join ClickStatistics s with (nolock) on a.TrackingID=s.TrackingID 
	where s.date between @FromDate and @ToDate or @IsGetAll = 1
	group by t.AffId

	union all

	select t.AffId, 
			0 as FDM, 
			sum(TotalClick) as TotalClicks, 
			Sum(UniqueClick) as TotalUniqueClicks,
			0 as TotalClicks_New,
			0 as TotalUniqueClicks_New
	from @TempAff as t 		
		inner join ClickStatisticsSum s with (nolock) on s.AffId=t.AffId
	where (s.date between @FromDate and @ToDate or @IsGetAll = 1)
			and IsForMonth = 0
			and TrackingId = 0
	group by t.AffId

	Union All
	--Separate TotalClicks and Unique Click is better for performance
	select t.AffId, 
			0 as FDM, 
			0 as TotalClicks, 
			0 as TotalUniqueClicks,
			TotalClicks as TotalClicks_New,
			UniqueClicks as TotalUniqueClicks_New
	from @TempAff as t 		
		cross apply [dbo].[Aff_GetClickStatisticsNew_Func](t.AffId, @FromDate, @Todate)

	) as t on tmp.AffId = t.AffId
Group by tmp.AffId, tmp.Username, tmp.IsClosed



GO
GRANT EXECUTE ON [dbo].[Aff_ActiveMemberReport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ActiveMemberReport] TO [VNTeam] 