Alter Procedure [Aff_AffiliateStatementHistorySel]  
	@AffId int,  
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT  
AS  
/*Created: 20091225@Peter
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateStatementHistorySel]  
Revisions:  	
Param's Explanation:  
• @AffID : Affiliate custid  
• @PageSize : Size of page
• @PageIndex : current page
• @TotalPages : number of pages
• @NRows : number of rows
*/  
SET NOCOUNT ON

declare @AffTrans table(TransId bigint, MonthDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description varchar(200))
declare @Month int,
	   @Year int,	  
	   @Currentdate datetime,
	   @NetPercentReceived float
	   
select @NetPercentReceived=1.0,@CurrentDate=current_timestamp     


insert into @AffTrans
select 0 as TransID,current_timestamp as MonthDate, 0 as TransType, sum (isnull(Amount,0)) *@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'Current Month Statistics' as Description             
from  Aff_CommissionForCurrentMonth(@AffID)

--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc
if(not exists (select (1) from AffCommission with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) and 
  datediff(m,(select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1)
BEGIN
  select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))
  
  insert into @AffTrans
  select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as MonthDate, 0 as TransType, sum (isnull(Amount,0)) *@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'UnCalculated Month' as Description	
  from  Aff_CommissionForMonth(@AffID,@Month,@Year)

END

insert into @AffTrans

select TransID, a.TransDate as MonthDate, TransType, (case when transtype=202 then abs(a.Amount) else a.Amount end) as Amount, (case when transtype=203 then 'B/F' else a.Status end) as  Status, isnull(i.username,'System') as Creator, case when TransType = 203 then '' else coalesce(p.AffDesc,a.Description) end as Description
from AffTrans a (nolock)
	 left join AffPayout p (nolock) on p.RefID=a.RefID
	left join Affiliate_User i with (nolock) on i.custid=a.Creator 
where a.AffId = @AffId
	and TransType in (202, 203)--202: Payment request and 203 : adjustment
Union All

Select 0 as TransId, a.MonthDate, 201 as TransType, isnull(a.Amount, 0) + isnull(b.Amount, 0) as Amount, 'B/F', 'System',  a.Description
From
	(select TransDate as MonthDate, Amount,  Description
	from AffTrans a (nolock)
	where AffId = @AffId
		and TransType = 201--201: Monthly Transfer
	)a left join
	
	(select TransDate as MonthDate, Amount
	from AffTrans a (nolock)
	where AffId = @AffId
		and TransType = 204--204 : Marketing fee(deduction 20% per Affiliate Net Winlost)
	) b on a.MonthDate = b.MonthDate 


select @NRows = Count(*)
From @AffTrans

DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 
 
select TransId, MonthDate, TransType, Amount, Status, Creator, Description
from  
	(
		select ROW_NUMBER() OVER(ORDER BY MonthDate desc) AS TheCount, 
			TransId, MonthDate, TransType, Amount, Status, Creator, Description
		from @AffTrans
	)m  
where m.TheCount between @RowStart and @RowEnd 



GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatementHistorySel] TO [VNTeam]

