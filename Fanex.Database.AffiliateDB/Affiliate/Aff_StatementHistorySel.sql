ALTER Procedure [dbo].[Aff_StatementHistorySel]    
 @AffId int,    
 @TransType int = -1,     
 @FDate smalldatetime = null,    
 @TDate smalldatetime = null,    
 @PageSize int=50,    
 @PageIndex int=1,    
 @TotalPages int=0 OUTPUT,    
 @NRows int=0 OUTPUT    
AS    
/*Created: 20090901@Peter  
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
DB:   
Original: [Aff_CustomerSelStatementHistory]    
Revisions:     
Param's Explanation:    
• @AffID : Affiliate custid    
• @TransType :   
             + 201 : Monthly Winlost  
             + 202 : Payment Request  
             + 203 : Adjustment    
             + -1 : Get all   
• @FDate : search From date (null: get all)  
• @TDate : search To date    (null: get all)  
• @PageSize : Size of page  
• @PageIndex : current page  
• @TotalPages : number of pages  
• @NRows : number of rows  
*/    
SET NOCOUNT ON  
if (@FDate is not null and @TDate is not null and @FDate>@TDate)  
  return   
if(@TDate>current_timestamp)  
  select @TDate=current_timestamp  
    
if @FDate is not null  
  set @FDate=dbo.Aff_GetStartDate(@FDate)  
  
if  @TDate is not null  
  set @TDate= dbo.Aff_GetEndDate(@TDate)  
    
    
declare @AffTrans table(TransId bigint, MonthDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description nvarchar(300))  
declare @Month int,  
       @Year int,  
       @Amount money,   
       @Currentdate datetime,  
       @NetPercentReceived float  
  select @NetPercentReceived=1.0,@CurrentDate=current_timestamp        
  
if (@FDate is null or @TDate is null or @Currentdate between @FDate and @TDate)  
begin  
exec [dbo].[Aff_CalMonthlyEarningCurrent]   
@AffID =@AffID,  
@Amount=@Amount OUTPUT  
  
insert into @AffTrans  
select 0 as TransID,current_timestamp as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'Current Month Statistics' as Description                
  
end  
  
--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc  
if(not exists (select top(1) 1 from AffCommission with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) and   
  datediff(m,(select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1  
  and exists (select top(1) 1 from AffDailySummary with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0)  
   and (@FDate is null or @TDate is null or dateadd(m,-1,@CurrentDate) between @FDate and @TDate)  
  )  
BEGIN  
  select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))  
  exec [dbo].[Aff_CalMonthlyEarning]   
  @AffID =@AffID,  
  @Month=@Month,  
  @Year=@Year,  
  @Amount=@Amount OUTPUT  
  
  insert into @AffTrans  
  select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'UnCalculated Month' as Description   
END  
  
  
  
insert into @AffTrans  
 select a.TransID, a.TransDate as MonthDate, a.TransType,(case when transtype=202 then abs(a.Amount) else a.Amount end) as Amount,(case when transtype=201 or transtype=203 then 'B/F' else a.Status end) as  Status, isnull(i.username,'System') as Creator, (
case when transtype=202 then ap.AdminDesc else a.Description end)  
     from AffTrans a (nolock)  
     left join AffPayout ap (nolock) on ap.RefID=a.RefID  
     left join AdminUser i with (nolock) on i.custid=a.Creator     
       
where a.AffID=@AffID  
  and (@TransType=-1 or TransType=@TransType)  
  and (@FDate is null or @TDate is null or (case when TransType=201 or a.CompletedDate Is null then a.TransDate else a.CompletedDate end ) between @FDate and @TDate)  
 and a.status in ('pending','approved','completed')  
  ORDER BY (case when a.status='pending' then 1 else 2 end), a.CompletedDate desc,a.TransType desc, a.TransID desc  
    
    
  
select @NRows=count(*) from @AffTrans  
--Add more row if the month is completed but not transfer yet  
     
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
where m.TheCount between @RowStart and @RowEnd  order by monthdate desc  





GO
GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_StatementHistorySel] TO [VNTeam]