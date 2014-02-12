USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSel]    Script Date: 04/04/2013 11:25:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER PROCEDURE [dbo].[Aff_BannerSel]	
	@Category smallint=NULL,
	@Language varchar(8)=NULL,
	@ImageType smallint=NULL,
	@Size smallint=NULL,
	@Currency smallint=NULL,
	@Type tinyint=0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

/*Created: 20090328@DungTong
Task : Search all Aff Banner Paging
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20130207@Johnny: Filter by Type(1: normal banner; 2: media banners)
			  
Param's Explanation:
• @Category : Search by Category value=null :search all
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @Type: type of banners(1: normal banner; 2: media banners)
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/

SET NOCOUNT ON
 declare @SubCategory table(id int)
 
if isnull(@Category,0)<>0
begin
 insert into @SubCategory(id)
 select typeid from BannerTypes where  parentid= @Category
 union 
 select @Category
end 


--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE (@Category is null or Category in (select id from @SubCategory))
	  and (@Language is null or  Language=@Language)
       and (@ImageType is null or ImageType =@ImageType)
	    and (@Size is null or size =@Size)
	   and (@Currency is null or Currency =@Currency)	  
       and (@Type is null or Type=@Type)
	  

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	BannerID, [Content], Category,
	[Language],LanguageCode, ImageType, [Size],Lastupdate,Currency,Type,Version,TotalRequest,LastRequest
FROM(       
SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
				BannerID, [Content],btc.Value as Category,l.LanguageID as LanguageCode,
	            l.LanguageName as [Language],bti.Value as ImageType, bts.Value as [Size],
                Lastupdate,c.CurrencyName as Currency,b.Type,Version,TotalRequest,LastRequest
FROM Banners b with (nolock)
left Join BannerTypes bts on bts.TypeID = b.Size
left Join BannerTypes bti on bti.TypeID = b.ImageType
inner Join BannerTypes btc on btc.TypeID = b.Category
inner join Language l on l.LanguageID=b.Language
inner join Currency c on c.CurrencyID=b.Currency

WHERE (@Category is null or b.Category in (select id from @SubCategory))
	  and (@Language is null or  b.Language=@Language)
       and (@ImageType is null or b.ImageType =@ImageType)
	    and (@Size is null or b.size =@Size)
	   and (@Currency is null or b.Currency =@Currency)	  
       and (@Type is null or b.Type=@Type)
	  
	  
    
   ) x
 where x.TheCount between @RowStart and @RowEnd	  







GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSel] TO [VNTeam]