ALTER Procedure [dbo].[AffAdmin_CountrySelAll]		
	@Name NVARCHAR(255) = NULL,	
	@PageSize INT = 50,
	@PageIndex INT = 1,
	@TotalPages INT = 0 OUTPUT,
	@NRows INT=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Country N WITH (NOLOCK)	
where CountryName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	
SELECT CountryID, CountryName,Description,Icon,DisplayOrder,IsEnabled
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY CountryName asc) AS TheCount,
		C.*
	FROM Country C WITH (NOLOCK)		
	where CountryName like @Name
	) x
where x.TheCount >= @RowStart


