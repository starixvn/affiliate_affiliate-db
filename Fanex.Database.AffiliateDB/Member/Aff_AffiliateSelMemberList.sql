 ALTER PROCEDURE [dbo].[Aff_AffiliateSelMemberList]		
	@AffiliateID  int,
	@FromDate datetime=null,
	@ToDate datetime=null,
	@MemberType smallint=0,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT  
AS
/*
	Created: 20100812@Peter	
	Task : Get list of member for Affiliate
	DB:  DB052.Affiliate_ZZun for Testing
	Revisions:
		
		
	Param's Explanation:		
	       @MemberType=1 : None-Deposited members only
	       @MemberType=2 : Deposited members only.
	       @MemberType=0 : All members.
	       @FromDate=@ToDate : Get all members for all registerdate

*/
SET NOCOUNT ON

select @FromDate=dbo.Aff_GetStartDate(@FromDate)
select @ToDate=dbo.Aff_GetEndDate(@ToDate)

--count nrows    
select @NRows=count(1)    
 
 from MemberInfo c with (nolock)      
 where AffID=@AffiliateID
	and (case when @MemberType=0 then 1
	          when @MemberType=1 and CreatedDate is null then 1
	          when @MemberType=2 and CreatedDate is not null then 1
	          else 0 
	      end) = 1
	      
   and (case when @FromDate is null and @ToDate is null then 1
             when RegisteredDate between @FromDate and @ToDate then 1
             else 0
         end)=1    
             
  
if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
       
       
 select firstname,lastname,username,email,currency,RegisteredDate,IsRemoved,Description
 from
 (
 
 select ROW_NUMBER() OVER(ORDER BY IsRemoved,RegisteredDate desc,username ) AS TheCount,  firstname,lastname,username,email,e.code as currency,RegisteredDate,IsRemoved, (case when IsRemoved=1 then (select 'Member is removed since ' + CAST(RemovedDate as varchar(50)) from MemberRemoval mr (nolock) where mr.username=c.username ) else '' end) as Description
 from MemberInfo c with (nolock)         
 inner join Exchange e with (nolock) on e.ExchangeID=c.Currency
 where AffID=@AffiliateID
	and (case when @MemberType=0 then 1
	          when @MemberType=1 and c.CreatedDate is null then 1
	          when @MemberType=2 and c.CreatedDate is not null then 1
	          else 0 
	      end) = 1
	      
   and (case when @FromDate is null and @ToDate is null then 1
             when RegisteredDate between @FromDate and @ToDate then 1
             else 0
         end)=1    
     ) t
  where TheCount between @RowStart  and  @RowEnd
  order by IsRemoved,RegisteredDate desc,username 
         
         
             
   
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelMemberList] TO [vnTeam]
GO