CREATE PROCEDURE [dbo].[AffAdmin_HotNewsSel]
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
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language

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
IF(@todate is not null)
	SET @todate = DATEADD(DAY, 1, @todate)

select @Nrows=count(1)
from News with (nolock)
where important=coalesce(@Important,important)
      and (
          case when @fromdate is null or @todate is null then 1
                when posteddate between @fromdate and @todate then 1
                else 0
          end     
      )=1

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
       
if(@language is null)--select all column
begin
   
    select [message_en]		
		  ,[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,[creatorname]
		  ,[updatename]
		  ,[updateddate]
    from (
     SELECT [message_en]		  
		  ,n.[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,C.username as creatorname
		  ,u.username as updatename
		  ,[updateddate]
          ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount
	  FROM News n with (nolock)
			LEFT JOIN AdminUser C  WITH (NOLOCK) ON C.CUSTID=n.[creator]
			LEFT JOIN AdminUser u  WITH (NOLOCK) ON u.CUSTID=n.[updatedby]
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
     SELECT  coalesce(r.ResourceValue,News.message_en) as [message]
		    ,[posteddate]
		    ,[msgid]
            ,[important]
            ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount		  
	  FROM News with (nolock)		
	  INNER JOIN RefResources r with (nolock) ON 
		r.RefID = 'News' and r.LanguageCode = @language and News.MsgID = cast(r.ResourceKey as int)
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
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_HotNewsSel] TO [vnteam]