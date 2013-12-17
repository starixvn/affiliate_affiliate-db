ALTER Procedure [dbo].[Aff_AffiliateStatistics]
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@Currency smallint = 0,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report by date for all affiliate.
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateStatistics]
Revisions:
    - Remove un-used column in result table. And 
	- 20130802@Jim: fix bug active member not same  as Total Active Players in Affiliate Info
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

Select @Fromdate=isnull(@Fromdate,current_timestamp),@Todate=isnull(@Todate,current_timestamp)
Select @FromDate = dbo.Date_Only(@FromDate), @ToDate = dbo.Date_Only(@ToDate)
select @UserName= '%' + Coalesce(@UserName, '') + '%'
Select @Fromdate = dateadd(d, datediff(d, 0, @Fromdate), 0)
Select @ToDate = dateadd(s, -60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE (@IsGetAll=1 or ai.ApprovedDate <= dbo.Aff_GetEndDate(@ToDate)) 
	and ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage)
	and (@Currency=0 or  @Currency=ai.Currency)
	and (@AffType=0 or AffType = @AffType)
	
if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30), 
		ActiveAll int,FDMAll int,Active int, Dormant int,TotalFDM int , 
		NonDeposit int , TotalRegistered int, AffTypeName varchar(50))

insert into @TempAff(AffID,UserName,AffTypeName)
select m.AffId, m.username,m.AffTypeName
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage,at.Name as AffTypeName
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId		
		left join AffType at with (nolock) on ai.AffType = at.TypeID
	WHERE  (@IsGetAll=1 or ai.ApprovedDate <= dbo.Aff_GetEndDate(@ToDate))			
	and ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage)
	and (@Currency=0 or  @Currency=ai.Currency)
	and (@AffType=0 or AffType = @AffType)
	
	)m 
where m.TheCount between @RowStart and @RowEnd      

if @IsGetAll = 1
Begin
	update t
	set t.TotalFDM=isnull(a.Total,0),
		t.TotalRegistered=isnull(a.TotalRegistered,0),
		t.Active=isnull(b.Active,0)
	from  @TempAff t	
	left join  	
	(
		SELECT r.AffID,
			sum(1) as TotalRegistered,
			sum(case when CreatedDate is not null then 1 else 0 end) as Total		
		FROM @TempAff r
			inner join MemberInfo d WITH(NOLOCK) on r.AffId = d.AffId and d.IsRemoved=0		
		Group by r.AffID
	) a on a.AffId = t.AffId
   left join
	(
		Select r.AffId,
			Count(Distinct md.username) as Active			
		From  @TempAff r
			inner join MemberDaily md with(nolock) on md.AffID=r.AffID
		where (Turnover > 0 OR md.Deposit>0)
		Group by r.AffId
	)b on b.AffId = t.AffId
		
End
Else
Begin
	Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

	update t
	set 
		t.TotalFDM=isnull(a.TotalFDM,0),
		t.TotalRegistered=isnull(a.TotalRegistered,0),
		t.Active=isnull(b.Active,0)
	from  @TempAff t	
	left join  	
	(
		SELECT r.AffID,
			sum(case when RegisteredDate between @FromDate and @ToDate then 1 else 0 end ) as TotalRegistered,
			sum(case when CreatedDate is not null and CreatedDate between @FromDate and @ToDate and RegisteredDate between @FromDate and @ToDate then 1 else 0 end) as TotalFDM
		FROM @TempAff r
			inner join MemberInfo d WITH(NOLOCK) on r.AffId = d.AffId
		where d.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
		Group by r.AffID
	) a on a.AffId = t.AffId
	left join
	(
		Select r.AffId,
			Count(Distinct md.username) as Active
		From  @TempAff r
			inner join MemberDaily md with(nolock) on md.AffID=r.AffID
			inner join MemberInfo mi with (nolock) on mi.username=md.username 				
		where (Turnover > 0 OR md.Deposit>0) 
			and md.WinlostDate between @FromDate and @ToDate			
			and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
		Group by r.AffId
	)b on b.AffId = t.AffId
End

Select * from @TempAff 





GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatistics] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatistics] TO [VNTeam] 
GO


