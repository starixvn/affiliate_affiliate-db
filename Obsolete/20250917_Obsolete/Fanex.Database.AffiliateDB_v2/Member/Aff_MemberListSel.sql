ALTER PROCEDURE [dbo].[Aff_MemberListSel]
	@AffUsername nvarchar(50) = null,
	@Username nvarchar(30) = null,    
	@AffType int = 0,	
	@PageSize int=50,
	@PageIndex int=1 OUTPUT,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
	Created: 20090701@VinhTrinh	
	DB: DB05.Affiliate_ZZun

	Revisions:		
	           -20100112@Peter : 	Shorting the page by CreatedDate . Request from Fan	
*/
SET NOCOUNT ON
declare @AffID int, @CurrDate smalldatetime

If @AffUsername is not null
Begin
	select @AffID = AffId from AffInfo with (nolock) where Username = @AffUsername and (@AffType = 0 or AffType = @AffType)
	if @AffID is null 
		return
End


select @CurrDate = dateadd(d, 0, (datediff(d, 0, current_timestamp)))

select @Username = '%' + isnull(@Username, '') + '%'

select @NRows = count(1)
from MemberInfo m with (nolock)
	inner join AffInfo a with(nolock) on m.AffID = a.AffID
where (case 
			when @AffID is null then 1 
			else 
				case when @AffID = a.AffID then 1 else 0 end
			end
		) = 1
	and m.Username like @Username
	and (@AffType = 0 or a.AffType = @AffType)
	and m.IsRemoved=0
	
if(isnull(@NRows,0)=0) return	
   
DECLARE @RowStart int, @RowEnd int

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex=(case when @PageIndex > @TotalPages then @TotalPages else @PageIndex end),
       @RowStart = @PageSize * (@PageIndex-1) + 1, @RowEnd = @RowStart + @PageSize - 1
         

select m.UserName,  e.Code as Currency, m.FirstName, m.LastName, 
	m.CreatedDate,m.RegisteredDate, m.AffID, m.AffUserName as AffUserName,
	m.AffTypeName
from
	(select ROW_NUMBER() OVER(ORDER BY m.CreatedDate desc) AS TheCount,
		 m.UserName, m.Currency as Currency, m.FirstName, m.LastName, m.CreatedDate,m.RegisteredDate,
		  m.AffID, af.UserName as AffUserName,at.Name as AffTypeName
	from MemberInfo m with (nolock)
		INNER JOIN AffInfo af with (nolock) on m.AffID = af.AffId
		left join AffType at with (nolock) on af.AffType = at.TypeID
	where (case 
			when @AffID is null then 1 
			else 
				case when @AffID = af.AffID then 1 else 0 end
			end
			) = 1
		and m.Username like @Username
		and (@AffType = 0 or af.AffType = @AffType)
		and m.IsRemoved = 0
	)m
  inner join Exchange e (nolock) on e.ExchangeID=m.Currency
where m.TheCount between @RowStart and @RowEnd
order by m.RegisteredDate desc, m.UserName asc

GO
GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberListSel] TO [vnteam]