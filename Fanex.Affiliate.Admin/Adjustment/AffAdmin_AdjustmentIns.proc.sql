ALTER PROCEDURE [dbo].[AffAdmin_AdjustmentIns]  
	@Amount  money,   
	@AffID  int,  
	@AdminID int,   
	@Description nvarchar(300) = '',  
	@ip   nvarchar(15) = '',  
	@Language varchar(5) = 'en-US',    
	@ErrCode int = 0 OUTPUT
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
    3) @Description Description of transaction  
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
	@ErrCode=@ErrCode output
  
If @ErrCode <> 0  
	RETURN  
  
IF @Amount = 0  
BEGIN  
	Select @ErrCode = 1011
	return  
END 
  
if(not exists(select 1 from AffInfo(nolock) where AffID=@AffID ))  
begin  
	SELECT @ErrCode = 1006  
	RETURN  
end  
  

Declare @AffCurrency varchar(5), @AffCurrencyCode varchar(5), @SysCurrency varchar(5), @SysExRate float, @Status varchar(30), @IsClosed bit, @MaxAmount money
  
select @AffCurrency = b.Currency,  @Status = Status, @IsClosed = IsClosed, @AffCurrencyCode = e.Code
from AffInfo b with (nolock)   
	inner join Exchange e (nolock) on e.ExchangeId=b.currency  
where AffID = @AffID  

SET @MaxAmount = (Select SValue From SystemSettings (nolock) where SName = 'AFF_MaximumAdjustment' + @AffCurrencyCode)

--Check Data 
if (@AffCurrency is null or ABS(@Amount) > @MaxAmount)
Begin  
	Select @ErrCode = 1011 
	return  
End 
 
if @Status <> 'Approved'  
Begin  
	Select @ErrCode = 1013
	return  
End  
  
if @IsClosed = 1  
Begin  
	Select @ErrCode = 1014
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
	@Description,  
	@AdminID,  
	@AffCurrency,  
	@SysCurrency,  
	@SysExRate,  
	203,--Adjustment TransType  
	0
)
/*set @transid=SCOPE_IDENTITY() */  
 
if @@ERROR <> 0  
begin  
	Select @ErrCode = 1005   
	return  
end      

 -- Recalculate BF in AffInfo table  
update AffInfo with (rowlock,updlock)  
Set BF=dbo.Aff_GetAffBalance (AffID)  
where AffID=@AffID 
 
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
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSel] TO [vnteam]