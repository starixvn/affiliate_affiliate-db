USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSelAll]    Script Date: 01/18/2013 16:30:50 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_ProductSelAll]		
	@Name varchar(255) = NULL,	
	@PageSize int = 50,
	@PageIndex int = 1,
	@TotalPages int = 0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Product N WITH (NOLOCK)	
where ProductName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	
SELECT ProductID, ProductName,Description,au.username AS Creator,CreatedDate,BettypeList
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY ProductName asc) AS TheCount,
		C.*
	FROM Product C WITH (NOLOCK)		
	where ProductName like @Name
	) x
LEFT JOIN AdminUser au ON x.Creator = au.custid
where x.TheCount >= @RowStart
