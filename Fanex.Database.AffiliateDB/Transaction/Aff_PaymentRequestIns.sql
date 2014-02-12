ALTER PROCEDURE [dbo].[Aff_PaymentRequestIns]  
	@AffID int,  
	@Player_UserName varchar(30), 	
	@Player_IBCUserName varchar(30), 	
	@Player_Currency varchar(5),	
	@Amount money,   
	@IP varchar(20),   
	@language varchar(20) = 'en-US',  
	@PreferredLanguage varchar(5)='en-US' OUTPUT,  
	@TransDate datetime=null OUTPUT,  
	@TransID bigint =0 OUTPUT,  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
begin  
/*  
Created: 20130314@Johnny  
Task : Insert an payment request from Affiliate  
DB: DB052.Affiliate_ZZun  
Original:   
  
Revisions:  
	- 20130805@Don: Fixed bug "User able request an invalid amount which is lager than Balance Brought Forward"
  
Param's Explanation:  
.@AffID: Affiliate id,  
.@Amount : Amount to withdraw  
.@IP: ip of computer sent,  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert unsuccessful.  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
Declare @TransType int  
select @TransType=202  
--Checking Affiliate ID  
if(not exists (select 1 from AffInfo (nolock) where affid=@AffID and Status='approved' and IsClosed=0 ))  
 begin  
 Select @ErrMsg = case @language   
        when 'en-US' then 'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'zh-TW' then N'Oops, Your account is not existed or closed. Please contact administrator.'  
        when 'zh-CN' then N'Oops, Your account is not existed or closed. Please contact administrator.'  
        when 'th-TH' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'es-ES' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'vi-VN' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        else  N'Oops, Your account is not existed or closed. Please contact administrator.'      
       end,   
   @ErrCode = 3001  
      return   
 end  
--Checking Amount  
if(@Amount<=0)  
begin  
  Select @ErrMsg = case @language   
        when 'en-US' then 'Sorry, amount is invalid.'   
        when 'zh-TW' then N'????,?????'  
        when 'zh-CN' then N'????,?????'  
        when 'th-TH' then N'?????? ???????????????????.'   
        when 'es-ES' then N'La cantidad no es válida.'   
        when 'vi-VN' then N'Xin l?i, s? ti?n không h?p l?.'   
        when 'id-ID' then N'Maaf, jumlah tidak valid.'   
        else  N'Sorry, amount is invalid.'      
       end,   
   @ErrCode = 3002  
          return  
end  
-- Checking whether this account has a pending request.  
if Exists(Select 1 from AffPayout with(nolock) where AffID = @AffID and status = 'Pending')  
Begin  
 Select @ErrMsg = case @language   
        when 'en-US' then 'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'  
        when 'zh-TW' then N'???????“?????”,????????,??????????????,????????????'  
        when 'zh-CN' then N'???????“?????”,????????,??????????????,????????????'  
        when 'th-TH' then N'?????????????????????????????? ???????????????????????????? ???????????????????????????????????????????.'  
        when 'es-ES' then N'Tiene una solicitud pendiente. Para crear una nueva solicitud, debe cancelar la que tiene pendiente o esperar hasta que se haya procesado.'  
        when 'vi-VN' then N'B?n có m?t yêu c?u dang ch? x? lý. Ð? t?o m?t yêu c?u m?i, hãy h?y yêu c?u dang ch? x? lý ho?c d?i cho d?n khi yêu c?u dó du?c x? lý.'  
        when 'id-ID' then N'Ada permintaan Anda yang tertunda. Agar dapat membuat permintaan baru, harap batalkan permintaan yang tertunda, atau tunggu sampai permintaan sudah diproses.'  
        else  N'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'     
       end,   
 @ErrCode = 3003  
 return  
End  
  
--Checking Balance Brought Forward  
DECLARE @AffBalance money
SET @AffBalance = dbo.Aff_GetAffBalance(@AffID)
if((@AffBalance<=0) OR (@Amount > @AffBalance))
begin  
   Select @ErrMsg = case @language   
        when 'en-US' then 'Sorry, this Affiliate does not have enough money to withdraw.'  
        when 'zh-TW' then N'????,???????????????'  
        when 'zh-CN' then N'????,???????????????'  
        when 'th-TH' then N'?????? ????????????????????????????????????????????????.'  
        when 'es-ES' then N'El saldo del afiliado es insuficiente, por lo que no puede retirar fondos.'  
        when 'vi-VN' then N'Xin l?i, H?i viên này không có d? ti?n d? rút.'  
        when 'id-ID' then N'Maaf, Afiliasi ini tidak mempunyai cukup uang untuk ditarik.'  
        else  N'Sorry, this Affiliate does not have enough money to withdraw.'  
       end,   
      @ErrCode = 3004      
  return    
end  
  
--Get all related info and Check Preferred Payment  
declare @PreferredPayment varchar(20),@AffCurrencyID smallint, @AffCurrency varchar(5), @Member_ExRate float  

Select  @PreferredPayment= PreferredPayment, @PreferredLanguage=PreferredLanguage  
from AffDetail (nolock)  
where AffID=@AffID   
   
 IF @PreferredPayment <> 'Player' --Just support transfer to player account  
 BEGIN  
  Select @ErrMSg = case @language   
         when 'en-US' then 'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'zh-TW' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'zh-CN' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'th-TH' then N'??????! ?????????????? [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] ?????????????????? ??????????????????????????????????? '+ ''' ???????????? '+ ''' ?????????? ???????????????????????????????????'  
         when 'es-ES' then N'Lo sentimos. El método de pago [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] no está disponible. En este momento, el único método de pago válido es mediante la cuenta de jugador. Haga clic aquí para realizar cambios.'  
         when 'vi-VN' then N'R?t ti?c! Phuong pháp thanh toán [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] không kh? d?ng. T?i th?i di?m này, ch? có phuong pháp '+ '''Tài kho?n Ngu?i choi'+''' du?c h? tr?. Hãy nh?p vào dây d? th?c hi?n thay d?i.'  
         when 'id-ID' then N'Maaf! Metode pembayaran [Neteller, Transfer Bank,.. - affiliate'+'''s chosen one] tidak tersedia. Pada saat ini, hanya metode '+ '''Rekening Pemain'+''' yang didukung. Silakan klik di sini untuk membuat perubahan.'  
         else  N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
        end,  
      @ErrCode = 3005     
  return  
 END  
  
 --Check supported player's currency
declare @SupportedCurrencies varchar(100)

Select @SupportedCurrencies=SValue
from SystemSettings (nolock)
where Type='Meta' and SName='SupportedBaseCurrencies' 
 
 
 if(@SupportedCurrencies not like '%' + @Player_Currency + '%') 
 begin
	  Select @ErrMsg = case @language   
       when 'en-US' then 'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + '.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'zh-TW' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'zh-CN' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'th-TH' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'es-ES' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'vi-VN' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'id-ID' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       else  N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
      end,  
	@ErrCode = 3008  
	return 	
 end
 
declare @Player_ExRate float, @Player_CurrencyId int
  
   Select  @AffCurrencyId=Currency  
   from AffInfo (nolock)  
   where AffID=@AffID   
	
	Select @Player_CurrencyId = ExchangeId
	From CurrencyConverter nolock
	where PartnerCurrency = @Player_Currency

	--Get player's Exchange rate (row is aff currency, column is player currency)
   Select @Player_ExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @Player_CurrencyId, default)
  

-- check min amount for withdrawing  
 DECLARE @SName varchar(50),@MinAmount money   
 SELECT @MinAmount=cast(SValue as money)   
    from SystemSettings with(nolock)   
    where SName = 'AFF_Min'+ @PreferredPayment + @AffCurrency  
  
 IF @MinAmount is not null  and @Amount < @MinAmount   
 BEGIN  
  Select @ErrMSg = case @language   
        when 'en-US' then 'Invalid balance account or either the currency or payment method is not supported.'  
        when 'zh-TW' then N'????????????????????'  
        when 'zh-CN' then N'???????????????????'  
        when 'th-TH' then N'????????? ???? ???????? ????????????????? ??.'  
        when 'es-ES' then N'El saldo de la cuenta no es válido o la moneda o método de pago no están permitidos.'  
        when 'vi-VN' then N'Tài kho?n s? du không h?p l? ho?c lo?i ti?n t? hay phuong th?c thanh toán không du?c h? tr?.'  
        when 'id-ID' then N'Rekening saldo tidak valid, atau mata uangnya, atau metode pembayaran tidak didukung.'  
        else  N'Invalid balance account or either the currency or payment method is not supported.'   
       end,  
   @ErrCode = 3006    
  return  
 END  
 
 Declare @SysCurrency varchar(5), @SysCurrencyId smallint, @SysExRate float
 
 Select @SysCurrency=SValue
 from SystemSettings (nolock)
 where Type='Meta' and SName='SystemCurrency'

 Select @SysCurrencyId = ExchangeId
 From Exchange nolock
 where Code = @SysCurrency
 
	Select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @SysCurrencyId, default)


If (Exists(Select 1 From AffDetail nolock where AffId = @AffId and Player_Currency is null))
Begin--Update Player currency if it is null
	update AffDetail with(rowlock, updlock)
	Set Player_Currency = @Player_Currency
	where AffId = @AffId
End
  

BEGIN TRANSACTION  
BEGIN TRY  
    declare @RefNo bigint  
	Select @TransDate=current_timestamp

    --Insert into AffPayout(AffID,IBCCustID,UserName,IBCUserName,AffCurrency,Amount,MemberCurrency,MemberExRate,AffPayout,SysCurrency,SysExRate,TransDate,Status)  
    --values(@AffID,@Player_IBCCustID,@Player_UserName,@Player_IBCUserName,@AffCurrency,-@Amount,@Player_Currency,@Player_ExRate,-@Amount * @Player_ExRate,@SysCurrency,@SysExRate,@TransDate,'pending')   

	Insert into AffPayout(AffID, UserName, IBCUserName, AffCurrency, Amount, MemberCurrency, MemberExRate, AffPayout, SysCurrency, SysExRate, TransDate, Status)  
    values(@AffID, @Player_UserName, @Player_IBCUserName, @AffCurrencyId, -@Amount, @Player_CurrencyId, @Player_ExRate, -@Amount * @Player_ExRate, @SysCurrencyId, @SysExRate, @TransDate, 'pending')   
    
    Select @RefNo= SCOPE_IDENTITY()  
    
    insert into AffTrans(AffID, TransDate, Amount, Status, Description, Creator, AffCurrency, SysCurrency, SysExRate, TransType, RefID)  
	values(@AffID, @TransDate, -@Amount, 'pending', 'Request payout', @AffID, @AffCurrencyId, @SysCurrencyId, @SysExRate, @TransType, @RefNo)  
    select @TransID=SCOPE_IDENTITY()  
END TRY    
BEGIN CATCH  
	rollback transaction   
	select @@Error
    Select @ErrMsg = case @language   
       when 'en-US' then 'Insert transaction failed.'  
       when 'zh-TW' then N'??????'  
       when 'zh-CN' then N'??????'  
       when 'th-TH' then N'?????????????????????????? ??.'  
       when 'es-ES' then N'No se ha podido completar la transacción.'  
       when 'vi-VN' then N'Chèn giao d?ch không thành công.'  
       when 'id-ID' then N'Gagal menyisipkan transaksi.'  
       else  N'Insert transaction failed.'   
      end,  
	@ErrCode = 3007  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
         
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Affiliate request payout. Amount=' +  dbo.Aff_ToString(@Amount)         
  
select @SPName=OBJECT_NAME(@@ProcID)  
   
EXEC [dbo].[Aff_WriteLog]  
	@Creator=@AffID,   
	@AffID=@AffID,  
	@Typename= 'Payout',   
	@SPName=@SPName ,  
	@IP =@IP,  
	@Details=@LogData   
  
end

GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestIns] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestIns] TO [vnteam]
GO