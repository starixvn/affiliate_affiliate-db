Alter PROCEDURE [dbo].[Aff_HotNewsSel]
	@fromdate smalldatetime=null,
	@todate smalldatetime=null,
	@Important bit=null,
	@language	varchar(11) = null,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20090317@DungTong
Task : Search message hot news and paging
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106

Param's Explanation:
• @fromdate : <> null: from postdate
				null: select all
• @todate : <> null: to postdate
				null: select all
• @Important : select message is important or not
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows
				

*/
SET NOCOUNT ON

DECLARE @RowStart int, @RowEnd int,@AffiliateID int

select @Nrows=count(1)
from News with (nolock)
where important=coalesce(@Important,important)
	  and (
		  case when @fromdate is null or @todate is null then 1
				when posteddate between @fromdate and @todate then 1
				else 0
		  end     
	  )=1
	  
 if(isnull(@NRows,0)=0)
   return	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	   
if(@language is null)--select all column
begin
   
	select [message_en]
		  ,[message_cn]
		  ,[message_tw]
		  ,[message_es]
		  ,[message_th]
		  ,[message_vi]
		  ,[message_id]
		  ,[message_kr]
		  ,[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,[creatorname]
		  ,[updatename]
		  ,[updateddate]
	from (
	 SELECT [message_en]
		  ,[message_cn]
		  ,[message_tw]
		  ,[message_es]
		  ,[message_th]
		  ,[message_vi]
		  ,[message_id]
		  ,[message_kr]
		  ,n.creator
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,C.username as creatorname
		  ,u.username as updatename
		  ,[updateddate]
		  ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount
	  FROM News n with (nolock)
			LEFT JOIN Affiliate_User C  WITH (NOLOCK) ON C.CUSTID=n.creator
			LEFT JOIN Affiliate_User u  WITH (NOLOCK) ON u.CUSTID=[updatedby]
	  WHERE important=coalesce(@Important,important)
		   and (case when @fromdate is null or @todate is null then 1
					when posteddate between @fromdate and @todate then 1
					 else 0
			   end     
			)=1
	 ) x
	 where x.TheCount between @RowStart and @RowEnd
end
else --select for specific language
 begin
  
	 select message		  
		  ,[posteddate]
		  ,[msgid]	
		  ,[important]  	  
	from (
	 SELECT  case @language
					when 'en_US' then message_en	
					when 'zh-TW' then coalesce(message_tw,message_en)
					when 'zh-CN' then coalesce(message_cn,message_en)
					when 'es-ES' then coalesce(message_es,message_en)
					when 'th-TH' then coalesce(message_th,message_en)
					when 'vi-VN' then coalesce(message_vi,message_en)
					when 'id-ID' then coalesce(message_id,message_en)
					when 'ko-KR' then coalesce(message_kr,message_en)
					else message_en				
					end as [message]
			,[posteddate]
			,[msgid]
			,[important]
			,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount		  
	  FROM News with (nolock)			
	  WHERE important=coalesce(@Important,important)
		   and (case when @fromdate is null or @todate is null then 1
					when posteddate between @fromdate and @todate then 1
					 else 0
			   end     
			)=1
	 ) x
	 where x.TheCount between @RowStart and @RowEnd
 end



 GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel] TO [bodbDownlineNetView]
GO  
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsSel] TO [vnteam]
GO

