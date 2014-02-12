 ALTER PROCEDURE [dbo].[Aff_ReportQMDetail]
    @ProductID int=0,
	@AffID int,
	@Month int,
	@Year int,
	@AffCurrency varchar(8) = 'UUS' OUTPUT,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get List of Qualifying members report for one affiliate.
DB: DB052.Affiliate_ZZun
Original: 
Revisions:
    
Param's Explanation:
	
*/
SET NOCOUNT ON

DECLARE @TblResult TABLE(mycount int IDENTITY(1,1), username varchar(30), Product varchar(50), TurnOver money)

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@CurrDate smalldatetime, @QualifiedAmount Float

 
select @AffCurrency=e.Code,@QualifiedAmount=co.QualifiedAmount
from AffInfo ai (nolock)
inner join Exchange e (nolock) on e.ExchangeID=ai.Currency
inner join CommGroup co with (nolock) on ai.GroupId = co.GroupId

where ai.AffID=@AffID


 --Get First date and last date and current date in order to calculate turnover
Select @CurrDate =  dbo.Date_Only(current_timestamp),
	@FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime),
	@LastDay = dbo.Aff_GetLastDayOfMonth(@FirstDay)
	
Select @LastDay = (case when @LastDay >= @CurrDate then @CurrDate else @LastDay end)

   insert into @TblResult(username, Product, TurnOver)
	Select username,p.ProductName,
		sum(TurnOver* AffExRate) as TurnOver		
	From MemberDaily m with (nolock)
          inner join Product p (nolock) on p.ProductID=m.ProductID
	where  (@ProductID=0 or @ProductID=m.ProductID) and Winlostdate  between @FirstDay and @LastDay and AffID=@AffID
	Group by username,p.ProductName
	order by sum(TurnOver* AffExRate) desc , username,p.ProductName
   
select @NRows=@@ROWCOUNT   

 

if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int  
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       

select tb.*, (case when tb.TurnOver>=@QualifiedAmount then 1 else 0 end) as IsQualifiedMember  from @TblResult tb where mycount between  @RowStart and @RowEnd    


GO

declare @AffCurrency varchar(8),
	@TotalPages int,    
	@NRows int

exec [dbo].[Aff_ReportQMDetail]
    @ProductID =0,
	@AffID=4,
	@Month=4,
	@Year =2013,
	@AffCurrency =@AffCurrency OUTPUT,
	@PageSize =50,    
	@PageIndex =1,    
	@TotalPages =@TotalPages OUTPUT,    
	@NRows =@NRows OUTPUT      

GO
GRANT EXECUTE ON [dbo].[Aff_ReportQMDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQMDetail] TO [VNTeam] 