ALTER PROCEDURE [dbo].[Aff_ResourceKeySel]	
	@ResourceType varchar(50) =NULL,
	@LanguageCode varchar(8)=NULL,
	@Key varchar(50)=NULL,
	@Value nvarchar(256)=NULL,
	@PageSize int = 50,
	@PageIndex int = 1,
	@TotalPages int = 0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20110221@Peter
Task : Search Resources From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Key='%' + isnull(rtrim(ltrim(@Key)),'') + '%'
Select @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'
/*Select @ResourceType='%' + isnull(@ResourceType,'') + '%'
Select @LanguageCode='%' + isnull(@LanguageCode,'') + '%'*/

DECLARE @Types TABLE
(
  SName varchar(50)
)

if @ResourceType is null 
	insert into @Types select SName from systemsettings where type ='ResourceRefID'
	

--count nrows
select @NRows=count(1)
FROM RefResources N WITH (NOLOCK)	
where ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
	and LanguageCode=coalesce(@LanguageCode,LanguageCode) and ResourceKey like @Key
	and ResourceValue like @Value
	And LanguageCode in (select LanguageID from Language (nolock))

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

	
SELECT [ResourceID],[RefID], [LanguageCode], [ResourceKey],[ResourceValue],[Description]
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY ResourceKey asc) AS TheCount,
		[ResourceID],[RefID], [LanguageCode], [ResourceKey],[ResourceValue],[Description]
	FROM RefResources N WITH (NOLOCK)	
	where ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
			 and LanguageCode=coalesce(@LanguageCode,LanguageCode) and ResourceKey like @Key
				and (@Value = '%%' OR ResourceValue like @Value)
				And LanguageCode in (select LanguageID from Language (nolock))

	) x
	where x.TheCount >= @RowStart


	 
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeySel] TO [vnteam]