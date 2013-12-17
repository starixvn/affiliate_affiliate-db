ALTER Procedure [dbo].[AffAdmin_StatementHistorySel]    
	@AffId int,    
	@TransType VARCHAR(100) = NULL,
	@Status VARCHAR(100) = NULL,  
	@DateOption tinyint = 0, 
	@FromDate smalldatetime = null,    
	@ToDate smalldatetime = null,    
	@BaseCurrency	varchar(5) = ''
AS    
/*Created: 20090901@Peter  
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
DB:   
Original: [Aff_CustomerSelStatementHistory]    
Revisions:     
	- 20131126@Johnny: Fix filter by transaction type and status
Param's Explanation:    
• @AffID : Affiliate custid    
• @TransType :   
             + 201 : Monthly Winlost  
             + 202 : Payment Request  
             + 203 : Adjustment    
             + -1 : Get all   
• @FromDate : search From date (null: get all)  
• @ToDate : search To date    (null: get all)   
*/    
SET NOCOUNT ON  
if (@FromDate is not null and @ToDate is not null and @FromDate>@ToDate)  
  return   
if(@ToDate>current_timestamp)  
  select @ToDate=current_timestamp  
    
if @FromDate is not null  
  set @FromDate=dbo.Aff_GetStartDate(@FromDate)  
  
if  @ToDate is not null  
  set @ToDate= dbo.Aff_GetEndDate(@ToDate)  

DECLARE @AffCurrency SMALLINT, @SystemCurrency SMALLINT
		, @MonthlyTransferType int, @PaymentType int, @AdjustmentType int

Select @MonthlyTransferType = 201, @PaymentType = 202, @AdjustmentType = 203

DECLARE @TransStatusTable TABLE (TransStatus varchar(20))
INSERT INTO @TransStatusTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @Status, ',' )

DECLARE @TransTypeTable TABLE (TransType varchar(20))
INSERT INTO @TransTypeTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @TransType, ',' )


--Convert aff currency to system currency
Select @SystemCurrency = CurrencyId 
FROM Currency(nolock)
where CurrencyCode = (SELECT TOP 1 SValue from SystemSettings nolock WHERE SName = 'SystemCurrency' AND Type = 'Meta')

SELECT @AffCurrency = Currency
FROM AffInfo(nolock)
WHERE AffID=@AffId

declare @AffTrans table(TransId bigint, TransDate SmallDatetime, CompletedDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description nvarchar(300))  
declare @Month int,  
       @Year int,  
       @Amount money,   
       @Currentdate datetime,  
       @NetPercentReceived float  
  select @NetPercentReceived=1.0,@CurrentDate=current_timestamp        
  
if (@FromDate is null or @ToDate is null or @Currentdate between @FromDate and @ToDate)  
begin  
	exec [dbo].[Aff_CalMonthlyEarningCurrent]   
	@AffID =@AffID,  
	@Amount=@Amount OUTPUT  
  
	insert into @AffTrans  
	select 0 as TransID,current_timestamp as TransDate,NULL as CompletedDate, @MonthlyTransferType as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Processing' as Status,'' as Creator,'Current month statistics' as Description                
  
end  
  
--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc  
if(not exists 
	(select top(1) 1 
	from AffCommission with (nolock) 
	where AffID=@AffID 
		and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) 
		and datediff(m, (select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1  
		and exists (select top(1) 1 from AffDailySummary with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0)  
		and (@FromDate is null or @ToDate is null or dateadd(m,-1,@CurrentDate) between @FromDate and @ToDate)  
	)  
BEGIN  
	select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))  
	exec [dbo].[Aff_CalMonthlyEarning]   
		@AffID =@AffID,  
		@Month=@Month,  
		@Year=@Year,  
		@Amount=@Amount OUTPUT  
  
	insert into @AffTrans  
	select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as TransDate,NULL as CompletedDate, @MonthlyTransferType as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Processing' as Status,'' as Creator,'Waiting for settlement' as Description   
END  
 
insert into @AffTrans  
select a.TransID, a.TransDate, a.CompletedDate ,a.TransType,(case when transtype=@PaymentType then abs(a.Amount) else a.Amount end) as Amount
	,(case 
			when transtype=@MonthlyTransferType or transtype=@AdjustmentType then 'B/F' 
			when a.Status = 'Pending' then 'Processing'
			when a.Status = 'Completed' then 'Approved'
			else a.Status 
		end) as  Status
	, isnull(i.username,'System') as Creator, (case when transtype=@PaymentType then ap.AdminDesc else a.Description end)  
from AffTrans a (nolock)  
     left join AffPayout ap (nolock) on ap.RefID=a.RefID  
     left join AdminUser i with (nolock) on i.custid=a.Creator     
where a.AffID=@AffID  
ORDER BY (case when a.status='pending' OR a.status='Processing' then 1 else 2 end), a.CompletedDate desc,a.TransType desc, a.TransID desc  
    
   
select TransId, TransDate,CompletedDate, TransType,
		CASE @BaseCurrency 
			WHEN '' THEN Amount 
			else Amount * dbo.Aff_GetExchangeRate(@AffCurrency, @SystemCurrency, null) 
		end as Amount,
		Status, Creator, Description  
from @AffTrans as a
where (@DateOption = 0 OR (@DateOption = 1 AND a.TransDate BETWEEN @FromDate AND @ToDate)
							OR (@DateOption = 2 AND a.CompletedDate BETWEEN @FromDate AND @ToDate))
		and (@TransType is null or a.TransType IN  (SELECT * FROM @TransTypeTable))
		and a.status in (SELECT * FROM @TransStatusTable)
order by TransDate desc 


GO
GRANT EXECUTE ON [dbo].[AffAdmin_StatementHistorySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_StatementHistorySel] TO [vnteam]