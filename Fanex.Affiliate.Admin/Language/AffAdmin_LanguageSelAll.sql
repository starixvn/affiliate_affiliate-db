ALTER PROCEDURE [dbo].[AffAdmin_LanguageSelAll]        
    @Name nvarchar(255) = NULL,    
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
BEGIN
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Revision:
-20151221@Francis: Support SSO

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

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
    
SELECT LanguageID, LanguageName,CountryID, au.UserID AS Creator
		,ISNULL(au.username, 'System') AS CreatorName, CreatedDate,CountryName
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY LanguageName asc) AS TheCount,
        L.*, C.CountryName
    FROM [Language] L WITH (NOLOCK)        
    left join Country C on C.CountryID = L.CountryID
    where LanguageName like @Name
    ) x
LEFT JOIN dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) au ON x.Creator = au.UserID
where x.TheCount >= @RowStart
END