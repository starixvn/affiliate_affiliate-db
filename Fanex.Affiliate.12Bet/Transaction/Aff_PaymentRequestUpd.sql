/****** Object:  Stored Procedure dbo.Aff_PaymentRequestUpd_xpre    Script Date: 12/25/2010 7:01:54 AM ******/  
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestUpd    Script Date: 12/16/2010 1:55:00 PM ******/  
Alter PROC [dbo].[Aff_PaymentRequestUpd]   
 @TransID bigint,   
 @Status nvarchar(50),  
 @AdminDesc nvarchar(300) = null,  
    @AffDesc nvarchar(300) = null,  
    @PreferredLanguage varchar(20)='en-US' OUTPUT,  
    @MailOption bit = 0 OUTPUT,  
 @UserID int,   
 @IP varchar(15) = '',  
 @RefNo bigint=0,  
 @language varchar(20) = 'en-US',  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
-- DB: DB052.Affiliate_12Bet  
/*  
Creator : Peter@20090910  
Task : Update Payment status ('Approved','Rejected','Cancelled')  
  
Input   
    1) @AffId (For Double check)   
    2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )  
    3) @Status Status of transaction  
    3) @AdminDesc Description for this payment from Admin  
    4) @AffDesc Description visible for Affiliate  
    5) @userid ID of Admin update this payment  
    6) @IP IP update payment  
     
Revisions:  
  
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
• @ErrMsg: Error description.  
*/  
  
  
--Check whether this is pending payment request   
SET NOCOUNT ON  
Declare @AffID int, @RefID bigint , @TransType int  
Select @TransType = 202  
Select @AffID=AffID,@RefID=RefID  
from AffTrans (nolock)  
where TransID=@TransID and TransType= @TransType and Status='pending'  
  
if(@AffID is null or @RefID is null)  
BEGIN  
           Select @ErrMsg = case @language   
        when 'en-US' then 'This transaction is not a withdrawal.'   
        when 'zh-TW' then N'此次交易不是提款操作。'  
        when 'zh-CN' then N'此次交易不是提款操作。'  
        when 'th-TH' then N'รายการที่แจ้งไม่ใช่รายการถอน คะ'   
        when 'es-ES' then N'La transacción no es una retirada de fondos.'   
        when 'vi-VN' then N'Giao dịch này không phải là giao dịch rút tiền.'   
        when 'id-ID' then N'Transaksi ini bukan penarikan dana.'  
		when 'ko-KR' then N'이 거래는 출금되지 않습니다.' 
        else  N'This transaction is not a withdrawal.'     
       end,   
   @ErrCode = 4001  
 return  
END  
  
/*Check Condition to excute this sp  
  + From Affiliate Site : @UserID=@AffID and  @Status='Cancelled'  
  + From AffAdmin Site: @UserID<> @AffID and Status in ('Approved','Rejected')   
*/  
if( @UserID<>@AffID)  
BEGIN  
 --Check permission-----------------------------  
  EXEC [dbo].[Aff_Con_CheckPermission_xpre]  
  @custid=@UserID,@funcname='[Payment]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output    
 If @ErrCode <> 0  
  RETURN  
     if(@Status not in ('Approved','Rejected'))  
  BEGIN  
       Select @ErrMsg = case @language   
          when 'en-US' then 'Oops, You do not have permission to update this transaction.'  
          when 'zh-TW' then N'Oops, You do not have permission to update this transaction.'  
          when 'zh-CN' then N'Oops, You do not have permission to update this transaction.'  
		  when 'ko-KR' then N'죄송합니다. 고객님은 본 거래를 업데이트 할 수 있는 권한이 없습니다.'
          else  N'Oops, You do not have permission to update this transaction.'     
         end,   
     @ErrCode = 4003  
   return  
  END  
END  
  
if(@UserID=@AffID and  @Status<>'Cancelled')  
BEGIN  
           Select @ErrMsg = case @language   
        when 'en-US' then 'Oops, You do not have permission to update this transaction.'  
        when 'zh-TW' then N'Oops, You do not have permission to update this transaction.'  
        when 'zh-CN' then N'Oops, You do not have permission to update this transaction.'  
		when 'ko-KR' then N'죄송합니다. 고객님은 본 거래를 업데이트 할 수 있는 권한이 없습니다.'
        else  N'Oops, You do not have permission to update this transaction.'     
       end,   
   @ErrCode = 4002  
 return  
END  
  
  
  
BEGIN TRANSACTION  
BEGIN TRY  
    declare @CompletedDate datetime  
     Select @PreferredLanguage=PreferredLanguage  
   , @MailOption = MailOption  
     from AffDetail (nolock)  
     where AffID=@AffID   
       
    Select @CompletedDate=current_timestamp  
    Update  AffPayout with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        AdminDesc=isnull(@AdminDesc,AdminDesc),  
        AffDesc=isnull(@AffDesc,AffDesc)  
    where RefID=@RefID and AffID=@AffID  
      
    Update  AffTrans with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        Creator=@UserID  
    where TransID=@TransID and AffID=@AffID       
END TRY  
  
BEGIN CATCH  
 rollback transaction   
    Select @ErrMsg = case @language   
       when 'en-US' then 'Insert transaction failed.'   
       when 'zh-TW' then N'插入交易失敗'  
       when 'zh-CN' then N'插入交易失败'  
       when 'th-TH' then N'ระบุรายการเลขที่ไม่ถูกต้อง คะ'   
       when 'es-ES' then N'No se ha podido completar la transacción.'   
       when 'vi-VN' then N'Chèn giao dịch không thành công.'   
       when 'id-ID' then N'Gagal menyisipkan transaksi.'  
	   when 'ko-KR' then N'신청하신 거례가 실패하였습니다.' 
       else  N'Insert transaction failed.'     
      end,  
  @ErrCode = 4004  
 return  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
  
  
declare @SPName varchar(50), @LogData nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @LogData =  'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserID,   
 @AffID=@AffID,  
 @Typename= 'Payout',   
 @SPName=@SPName ,  
 @RefNo=@RefNo,  
 @IP =@IP,  
 @Details=@LogData

GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestUpd] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestUpd] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestUpd] TO [vnteam]
GO