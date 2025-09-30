ALTER PROC [dbo].[Aff_MemberInfoSel]
	@AffID int,	
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Joseph
Task : Get member of affiliate.
DB: DB052.Affiliate_12BET
Revisions:
    
*/
Set Nocount On


--count nrows
select @NRows=count(1)    
FROM  MemberInfo mi with (nolock)  	
WHERE mi.AffID = @AffID

if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
select m.*
from  
	(select ROW_NUMBER() OVER(ORDER BY mi.UserName) AS TheCount,  
		mi.UserName,'' as FirstName, '' as LastName, mi.Email, 
		mi.CreatedDate,mi.RegisteredDate, '' as MobileNumber
	from MemberInfo mi with (nolock)    		
	where mi.AffID = @AffID
	)m 
where m.TheCount between @RowStart and @RowEnd      

GO
GRANT EXECUTE ON [dbo].Aff_MemberInfoSel TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].Aff_MemberInfoSel TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].Aff_MemberInfoSel TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Aff_MemberInfoSel TO [VNTeam]