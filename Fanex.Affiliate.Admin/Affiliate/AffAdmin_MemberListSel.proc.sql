ALTER PROCEDURE [dbo].[AffAdmin_MemberListSel]    
	@UserId int,  
	@AffUsername nvarchar(50) = null,    
	@Username nvarchar(30) = null,      
	@AffType varchar(30) = null,
	@CurrencyList varchar(100) = NULL,
	@MemberType tinyint = 0,
	@DateOption tinyint = 0,
	@FromDate smalldatetime = null,
	@ToDate smalldatetime = null,
	@SortBy tinyint = 0, 
	@ExcludeTest bit = 1,
	@IsITAdmin bit = 1,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT  
AS
/*    
 Created: 20090701@VinhTrinh     
 DB: DB05.Affiliate_ZZun    
    
 Revisions:      
            -20100112@Peter :  Shorting the page by CreatedDate . Request from Fan     
      -20130808@Jim: restrict user permission by currency      
      -20131003@Joseph: add more parameters
 Param's Explanation: 
• @UserId: Admin UserID
• @AffUserName: Affiliate name to search 
• @UserName: Member name
• @AffType: Affiliate type (1,2...)
• @CurrencyList: list of currencies separated by commas, Ex: '1,2,3'
• @MemberType: 
	. All (0): search all members.
	. Deposit (1): search all members that have the value "First Deposit Date".
	. Non-Deposit (2):  search all members that don't have the value "First Deposit Date".
• @DateOption: 
	. All (0): No date criteria
	. Registered Date(1): Registered Date must be between @FromDate and @EndDate
	. First Deposit Date (2): Created date must be between @FromDate and @EndDate	
• @SortBy
	. User Name: 0
	. Registered Date: 1
	. First Deposit Date: 2	
• @ExcludeTest: exclude test account or not
*/    
SET NOCOUNT ON    
declare @AffID int, @CurrDate smalldatetime    

select  AttributeID as CurrencyID INTO #tmpCurrency    
from dbo.Aff_f_GetCurrencybyUser (@UserId,1)   

    
-- declare #TblAffType table (id int primary key, rank int, val nvarchar( 6) )
select val 
into #TblAffType 
 from [dbo].[strSplit] ( @AffType, ',' )

SELECT a.val
INTO #TblCurrency 
FROM [dbo].[strSplit] ( @CurrencyList, ',' ) a
	inner join #tmpCurrency b on a.val = b.CurrencyID

If @AffUsername is not null    
Begin    
	select @AffID = AffId from AffInfo with (nolock) 
	where Username = @AffUsername and (@AffType is null or AffType in (select val from #TblAffType))    
	if @AffID is null     
		return    
End    
  
select @CurrDate = dateadd(d, 0, (datediff(d, 0, current_timestamp)))    
    
select @Username = '%' + isnull(@Username, '') + '%'    
    
select @NRows = count(1)    
from MemberInfo m with (nolock)    
	inner join AffInfo a with(nolock) on m.AffID = a.AffID    
where 
	(case     
			when @AffID is null then 1     
			else     
				case when @AffID = a.AffID then 1 else 0 end    
		end    
		) = 1
	and m.Username like @Username 
	and (@AffType IS NULL OR AffType in (select val from #TblAffType))    
	and (@CurrencyList IS NULL OR m.Currency in (select val from #TblCurrency))    
	and (@MemberType = 0 OR (@MemberType = 1 and m.CreatedDate is not null) or (@MemberType = 2 and m.CreatedDate is null))
	and (@DateOption = 0 OR (@DateOption = 1 AND m.RegisteredDate BETWEEN @FromDate AND @ToDate)
						OR (@DateOption = 2 AND m.CreatedDate BETWEEN @FromDate AND @ToDate))
	and ((@ExcludeTest = 1 AND a.TestLevel=0) OR (@ExcludeTest = 0 AND @IsITAdmin = 1) OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND a.TestLevel IN (0,1)))
	--and m.IsRemoved=0
     
--if(isnull(@NRows,0)=0) return     

DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
select m.RemovedDate,m.IsRemoved,m.UserName,  e.Code as Currency, m.FirstName, m.LastName, 
		m.Email,m.Phone,m.Address, m.Country,    
		m.CreatedDate,m.RegisteredDate, m.AffID, m.AffUserName as AffUserName,    
		m.AffTypeName  
from    
	(select ROW_NUMBER() OVER(ORDER BY CASE @SortBy WHEN 0 THEN m.UserName 
													ELSE null END,										
										CASE @SortBy WHEN 1 THEN m.RegisteredDate
													ELSE null END DESC,
										CASE @SortBy WHEN 2 THEN m.CreatedDate
													ELSE null END DESC
										) AS TheCount,  
										   
		mr.RemovedDate, m.IsRemoved,m.UserName, m.Currency as Currency, m.FirstName, m.LastName, 
		m.Email,m.Phone,m.Address, c.CountryName as Country,
		m.CreatedDate,m.RegisteredDate,    
		m.AffID, af.UserName as AffUserName,at.Name as AffTypeName  
	from MemberInfo m with (nolock)    
		INNER JOIN AffInfo af with (nolock) on m.AffID = af.AffId    
		left join AffType at with (nolock) on af.AffType = at.TypeID 
		left join Country c with (nolock) on m.CountryID = c.CountryID
		left join MemberRemoval mr with (nolock) on m.UserName = mr.UserName
	where (case     
				when @AffID IS NULL then 1     
				else     
					case when @AffID = af.AffID then 1 else 0 end    
			end ) = 1    
		and m.Username like @Username
		and (@AffType IS NULL or AffType in (select val from #TblAffType))    
		and (@CurrencyList IS NULL OR m.Currency in (select val from #TblCurrency))  
		and (@MemberType = 0 or (@MemberType = 1 and m.CreatedDate is not null) or (@MemberType = 2 and m.CreatedDate is null))
		and (@DateOption = 0 OR (@DateOption = 1 AND m.RegisteredDate BETWEEN @FromDate AND @ToDate)
							OR (@DateOption = 2 AND m.CreatedDate BETWEEN @FromDate AND @ToDate))
		and ((@ExcludeTest = 1 AND af.TestLevel=0) OR (@ExcludeTest = 0 AND @IsITAdmin = 1) OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND af.TestLevel IN (0,1)))
		-- and m.IsRemoved = 0    
	)m    
inner join Exchange e (nolock) on e.ExchangeID=m.Currency    
--inner join #tmpCurrency  tmp on m.Currency=tmp.CurrencyID    
where m.TheCount between @RowStart and @RowEnd    
--order by m.RegisteredDate desc, m.UserName asc    
----------------------    
drop table #tmpCurrency    
drop table #TblAffType    
drop table #TblCurrency    
---------------------- 

GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberListSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_MemberListSel] TO [vnteam]