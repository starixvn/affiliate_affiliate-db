 Alter PROCEDURE [dbo].[DEP_AffiliateSelMemberList]		
	@AffiliateID  int,
	@FromDate smalldatetime=null,
	@ToDate smalldatetime=null,
	@MemberType smallint=0,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT  
AS
/*
	Created: 20100812@Peter	
	Task : Get list of member for Affiliate
	DB: DBDEPOSIT.DEPOSIT_DB
	Revisions:
		
		
	Param's Explanation:		
		   @MemberType=1 : None-Deposited members only
		   @MemberType=2 : Deposited members only.
		   @MemberType=0 : All members.
		   @FromDate=@ToDate : Get all members for all registerdate

*/
SET NOCOUNT ON

select @FromDate=convert(varchar(10),@FromDate,120)
select @ToDate=dateadd(s,-1,dateadd(d,1,@ToDate)) 
--count nrows    
select @NRows=count(1)    
 
 from Deposit_Customer c with (nolock)      
 where AffiliateID=@AffiliateID
	and (case when @MemberType=0 then 1
			  when @MemberType=1 and IBCCustID is null then 1
			  when @MemberType=2 and IBCCustID is not null then 1
			  else 0 
		  end) = 1
		  
   and (case when @FromDate is null and @ToDate is null then 1
			 when creatdate between @FromDate and @ToDate then 1
			 else 0
		 end)=1    
			 
  
if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
	   
	   
 select firstname,lastname,username,email,currency,RegisteredDate
 from
 (
 
 select ROW_NUMBER() OVER(ORDER BY creatdate desc ) AS TheCount,  firstname,lastname,username,email,c.currency,creatdate as RegisteredDate
 from Deposit_Customer c with (nolock)      
 where AffiliateID=@AffiliateID
	and (case when @MemberType=0 then 1
			  when @MemberType=1 and IBCCustID is null then 1
			  when @MemberType=2 and IBCCustID is not null then 1
			  else 0 
		  end) = 1
		  
   and (case when @FromDate is null and @ToDate is null then 1
			 when creatdate between @FromDate and @ToDate then 1
			 else 0
		 end)=1    
	 ) t
  where TheCount between @RowStart  and  @RowEnd
		 
		 
			 
   

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateSelMemberList] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateSelMemberList] TO [VNTeam]