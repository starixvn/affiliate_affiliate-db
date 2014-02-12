USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSelAll]    Script Date: 02/28/2013 11:09:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_LanguageSelAll]		
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
FROM Language N WITH (NOLOCK)	
where LanguageName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	
SELECT LanguageID, LanguageName,CountryID,au.Username AS Creator,CreatedDate,CountryName
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY LanguageName asc) AS TheCount,
		L.*, C.CountryName
	FROM [Language] L WITH (NOLOCK)		
	left join Country C on C.CountryID = L.CountryID
	where LanguageName like @Name
	) x
LEFT JOIN dbo.AdminUser au on x.Creator = au.custid

where x.TheCount >= @RowStart
