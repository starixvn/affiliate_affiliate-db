Alter Procedure [Aff_AffiliateStatistics]
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
DB: DB052.Affiliate_12BET
Original: [Aff_CustomerSelDetailsByAff]
Revisions:
	
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
	and ai.IsClosed=0
	and ai.Username like @UserName
	and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
	and AffType = @AffType

if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
		
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30))

insert into @TempAff
select m.AffId, m.username
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
	where ai.Status = 'Approved'
		and ai.IsClosed=0
		and ai.Username like @UserName  
		and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		and AffType = @AffType
	)m 
where m.TheCount between @RowStart and @RowEnd      

if @IsGetAll = 1
Begin
	
	Select t.AffId,
		t.Username,
		Sum(isnull(Active, 0)) as Active,
		Sum(isnull(Total, 0)) as Total
	From @TempAff t left join
		(Select AffId, 
			0 as Active,
			Count(IBCCustID) as Total
		From MemberInfo with(nolock)
		Where AffId > 0
		Group by AffId
		
		Union All
		
		Select AffId,
			Count(Distinct IBCCustId) as Active,
			0 as Total
		From MemberDaily with(nolock)
		where Turnover > 0
		Group by AffId) t2 on t.AffId = t2.AffId
	Group by t.AffId, t.Username
End
Else
Begin

	Select t.AffId,
		t.Username,
		Sum(isnull(Active, 0)) as Active,
		Sum(isnull(Total, 0)) as Total
	From @TempAff t left join
		(Select AffId, 
			0 as Active,
			Count(IBCCustID) as Total
		From MemberInfo with(nolock)
		where AffId > 0 and CreatedDate between @FromDate and @ToDate
		Group by AffId
		
		Union All
		
		Select m.AffId,
			Count(Distinct m.IBCCustId) as Active,
			0 as Total
		From MemberDaily m with(nolock)
			inner join 
				(select IBCCustId 
				from MemberInfo with(nolock) 
				where CreatedDate between @FromDate and @ToDate
				) as t on m.IBCCustId = t.IBCCustId
		where Turnover > 0
			and WinlostDate between @FromDate and @ToDate
		Group by m.AffId) t2 on t.AffId = t2.AffId
	Group by t.AffId, t.Username
End

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatistics] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatistics] TO [VNTeam] 
GO