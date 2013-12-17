ALTER PROCEDURE [dbo].[AffAdmin_EmailHistorySel]  
	@MID int = NULL,  
	@SenderName nvarchar(50)=NULL,  
	@Email nvarchar(50)=NULL,  
	@AffiliateUserName varchar(30)=NULL,  
	@fromdate smalldatetime=null,  
	@todate smalldatetime=null,  
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT  
AS  
/*  
Created: 20090626@VinhTrinh  
Task : Insert new email for EmailHistory  
DB: DB052.Affiliate_ZZun  
Original:  

Revisions:  
	- 20131114@Johnny: fix bugs
Param's Explanation:  
• @MID : mail id  
        Null: search all  
        id>0 : search for id  
        <0 : search unknown email( affiliateid=-1)  
.@SenderName: search by sender name.  
.@Email: search by email      
.@AffiliateUserName: search by Affiliate User Name     
• @PageSize : Number of rows should be returned per each page  
• @PageIndex : Current page   
• @TotalPages OUTPUT : total of pages for this search  
  
• @NRows OUTPUT,--total of rows  
  
*/  
SET NOCOUNT ON  
DECLARE @RowStart int, @RowEnd int, @AffiliateID int  
  
    
--Search by unregistered affiliate  
if(@MID<0)  
begin  
   select @AffiliateID=-1,@MID=null  
end  
/*  
if (isnull(@AffiliateUserName,'')<>'')  
 begin    
     select @AffiliateID=AffId   
     from AffInfo with (nolock)  
     where username=@AffiliateUserName  
     if(coalesce(@AffiliateID,-2)=-2)  
        return  
 end  
 */  
--select @AffiliateUserName = '%' + Coalesce(@AffiliateUserName, '') + '%'   
select @SenderName= '%' + Coalesce(@SenderName, '') + '%'   
select @Email= '%' + Coalesce(@Email, '') + '%'    
  
select @Nrows=count(1)  
from EmailHistory with (nolock)  
where MID=Coalesce(@MID,mid)  
     and sender like @SenderName  
     and email like @Email  
	and ( 
		case when @AffiliateUserName is null THEN 1
			When AffName like '%' + @AffiliateUserName + '%' AND AffId > 0 THEN 1
			ELSE 0
		End) = 1
	and (  
		case when AffID = @AffiliateID or @AffiliateID is null then 1   
			else 0 
		end  
	) = 1  
	and (  
		case when @fromdate is null or @todate is null then 1  
			when CreatedDate between @fromdate and @todate then 1  
			else 0  
		end       
	)=1  
  
if(isnull(@NRows,0)=0)  
   return   
  
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,  
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1     
         
  
select mid,content,sender,AffId as AffiliateID,affname,email,subject,CreatedDate as CreateDate,ip,browser  
  from (  
     select mid,content,sender,AffId,affname,email,subject,CreatedDate,ip,browser,  
            ROW_NUMBER() OVER(ORDER BY CreatedDate desc,AffId asc) AS TheCount  
     from EmailHistory with (nolock)  
     where MID=Coalesce(@MID,mid)  
          and sender like @SenderName  
          and email like @Email  
          and ( 
			case when @AffiliateUserName is null THEN 1
				When AffName like '%' + @AffiliateUserName + '%' AND AffId > 0 THEN 1
				ELSE 0
			End) = 1 
    and (  
   case when AffID = @AffiliateID or @AffiliateID is null then 1   
   else 0 end  
   ) = 1  
          and (  
          case when @fromdate is null or @todate is null then 1  
                when CreatedDate between @fromdate and @todate then 1  
                else 0  
          end       
   )=1  
  ) x  
  where x.TheCount between @RowStart and @RowEnd  
  
  
GO
GRANT EXECUTE ON [dbo].[AffAdmin_EmailHistorySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_EmailHistorySel] TO [vnteam]