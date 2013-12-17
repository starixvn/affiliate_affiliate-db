

ALTER PROCEDURE [dbo].[Aff_BannerSelByParentCate]	
	@Category varchar(50)=NULL,
	@Language varchar(50)=NULL,
	@ImageType varchar(50)=NULL,
	@Size varchar(50)=NULL,
	@Currency varchar(50)=NULL,
	@Type varchar(50)=0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

/*Created: 2012-02-09 - Frank
Task : IRP-671-Banner Media
DB:  DB052.Affiliate_12BET

Revisions:    
	
			  
Param's Explanation:
• @Category : Search by all sub category which belong to Category
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/

SET NOCOUNT ON

Declare @MediaType varchar(50)
Set @MediaType = 'CategoryMedia' + @Category

--count nrows
select @NRows=count(1)
FROM Banners_1 with (nolock)
WHERE Category in (Select b.Value From BannerTypes_1 b Where b.Type like @MediaType)
	  and Language=coalesce(@Language,Language) 
	  and ImageType=coalesce(@ImageType,ImageType) 
	  and Size=coalesce(@Size,Size) 
	  and isnull(Currency,'')=coalesce(@Currency,Currency,'') 
	  and ISNULL([Type], 0) = @Type

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	BannerID, FileName, Category,
	[Language], ImageType, [Size],Lastupdate,Currency
FROM(       
SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
			BannerID, FileName, Category,
			[Language], ImageType, [Size],Lastupdate,Currency
FROM Banners_1 with (nolock)
WHERE Category in (Select b.Value From BannerTypes_1 b Where b.Type like @MediaType)
	  and Language=coalesce(@Language,Language) 
	  and ImageType=coalesce(@ImageType,ImageType) 
	  and Size=coalesce(@Size,Size) 
	 and isnull(Currency,'')=coalesce(@Currency,Currency,'') 
	 and ISNULL([Type], 0) = @Type
   ) x
 where x.TheCount between @RowStart and @RowEnd	  

GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelByParentCate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelByParentCate] TO [VNTeam]