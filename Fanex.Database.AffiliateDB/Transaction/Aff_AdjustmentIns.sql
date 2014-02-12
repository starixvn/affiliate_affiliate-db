ALTER PROCEDURE [dbo].[Aff_AdjustmentIns]  
 @Amount  money,   
 @AffID  int,  
 @AdminID int,   
 @transdesc nvarchar(300) = '',  
 @transid bigint OUTPUT,  
 @ip   nvarchar(15) = '',  
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg  nvarchar(200) = '' OUTPUT  
AS  
SET NOCOUNT ON  
-- DB: DB052.Affiliate_ZZun  
/*  
Creator : Vinh  
Date : 2009-07-30  
Task : Approve a payment request.  
  
Input   
 0) @Amount Adjusment amount  
    1) @AffId (For Double check)   
    2) @AdminID User insert transaction  
    3) @transdesc Description of transaction  
    4) @transid transid for this Adjustment  
    5) @userid ID of Admin update this Adjustment  
    6) @IP IP update Adjustment  
   Output  
    1) @ErrCode:  
  = 0: Transaction recorded successfully.  
  > 0: Specific Error.  
    2) @ErrMsg: Error description.  
Revisions:  
  
*/  
SET NOCOUNT ON  
  
--SELECT @ErrCode = 101, @ErrMsg = 'do it later..'  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@AdminID,  
 @funcname='[Payment]',--User the same with payment  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
If @ErrCode <> 0  
 RETURN  
  
IF @Amount = 0  
BEGIN  
 Select @ErrMsg = case @Language 
							when 'en-US' then 'Sorry, amount is invalid.'
							when 'zh-CN' then N'抱歉,總額是無效的'
							when 'zh-TW' then N'抱歉，总额是无效的'
							else N'Sorry, amount is invalid.'
						end, @ErrCode = 30001  
 return  
END  
  
if(not exists(select 1 from AffInfo(nolock) where AffID=@AffID ))  
begin  
 SELECT @ErrMsg = case @Language 
							when 'en-US' then 'Invalid Affiliate!'
							when 'zh-CN' then N'無效的工作夥伴!'
							when 'zh-TW' then N'无效的工作伙伴！'
							else N'Invalid Affiliate!'
						end
		, @ErrCode = 1001  
 RETURN  
end  
  
Declare @AffCurrency varchar(5), @SysCurrency varchar(5), @SysExRate float, @Status varchar(30), @IsClosed bit  
  
select @AffCurrency = b.Currency,  @Status = Status, @IsClosed = IsClosed  
from AffInfo b with (nolock)   
 inner join Exchange e (nolock) on e.ExchangeId=b.currency  
where AffID = @AffID  
  
  
--Check Data  
if @AffCurrency is null  
Begin  
 Select @ErrMsg = case @Language 
							when 'en-US' then 'Invalid Currency'
							when 'zh-CN' then N'無效的貨幣'
							when 'zh-TW' then N'无效的货币'
							else N'Invalid Currency'
						end,   
		@ErrCode = 30002  
 return  
End  
  
if @Status <> 'Approved'  
Begin  
 Select 
	@ErrMsg = case @Language 
							when 'en-US' then 'Sorry, You cannot do adjustment because this Affiliate is not approved yet.'
							when 'zh-CN' then N'抱歉,您無法調整,因為這個工作夥伴尚未核准'
							when 'zh-TW' then N'抱歉，您无法调整，因为这个工作伙伴尚未核准'
							else N'Sorry, You cannot do adjustment because this Affiliate is not approved yet.'
						end,
	@ErrCode = 30003  
	
	return  
End  
  
if @IsClosed = 1  
Begin  
 Select @ErrMsg = case @Language 
							when 'en-US' then 'Sorry, You cannot do adjustment because this Affiliate is closed.'
							when 'zh-CN' then N'抱歉,您無法調整,因為這個工作夥伴已經關閉'
							when 'zh-TW' then N'抱歉，您无法调整，因为这个工作伙伴已经关闭'
							else N'Sorry, You cannot do adjustment because this Affiliate is closed.'
						end,   
	@ErrCode = 30004  
 return  
End  
  
  
declare @CurrentDate datetime  
 Set @CurrentDate=current_timestamp  
  
select @SysCurrency=dbo.Aff_GetSystemCurrencyID()  
select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrency,@SysCurrency, default)  
  
insert into AffTrans([AffID]  
 ,[TransDate]  
 ,[CompletedDate]  
 ,[Amount]  
 ,[Status]  
 ,[Description]  
 ,[Creator]  
 ,[AffCurrency]  
 ,[SysCurrency]  
 ,[SysExRate]   
 ,[TransType]   
 ,[RefID])  
values(  
 @AffID,  
 @CurrentDate,  
 @CurrentDate,  
 @Amount,  
 'Completed',  
 @transdesc,  
 @AdminID,  
 @AffCurrency,  
 @SysCurrency,  
 @SysExRate,  
 203,--Adjustment TransType  
 0  
   
)  
set @transid=SCOPE_IDENTITY()   
  
if @@ERROR <> 0  
begin  
 Select @ErrMsg = case @Language 
							when 'en-US' then 'This transaction is unsuccessful.'
							when 'zh-CN' then N'這筆交易是不成功的'
							when 'zh-TW' then N'这笔交易是不成功的'
							else N'This transaction is unsuccessful.'
						end,   
	@ErrCode = 4005   
 return  
end  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Modify Balance Brought Forward. Amount = ' + dbo.Aff_ToString(@Amount)   
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @AdminID,  
 @AffID = @AffID,  
 @Typename = 'Adjustment', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
  
  

GO
GRANT EXECUTE ON [dbo].[Aff_AdjustmentIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdjustmentIns] TO [VNTeam]