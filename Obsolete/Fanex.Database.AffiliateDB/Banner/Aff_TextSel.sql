USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextSel]    Script Date: 01/29/2013 16:35:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextSel_1_xpre    Script Date: 4/3/2012 3:07:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextSel_1    Script Date: 2/24/2012 10:17:35 AM ******/

ALTER PROCEDURE [dbo].[Aff_TextSel]	
	@Category varchar(50)=NULL,
	@Language varchar(50)=NULL,
	@Currency varchar(50)=NULL,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

SET NOCOUNT ON

--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
      and [ImageType] = 'Text'
      and isnull(Currency,'')=coalesce(@Currency,Currency,'') 

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	BannerID, Category,
	[Language],Lastupdate,Currency,[Message]
FROM(       
SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
			BannerID, Category,
			[Language], Lastupdate,Currency,[Message]
FROM Banners with (nolock)
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
	  and [ImageType] = 'Text'
      and isnull(Currency,'')=coalesce(@Currency,Currency,'') 
   ) x
 where x.TheCount between @RowStart and @RowEnd