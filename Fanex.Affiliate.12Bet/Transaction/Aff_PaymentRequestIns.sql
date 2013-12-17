ALTER PROCEDURE [dbo].[Aff_PaymentRequestIns]    
 @AffID int,    
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
Created: 20090910@Peter    
Task : Insert an payment request from Affiliate    
DB: DB052.Affiliate_12Bet    
Original:     
    
When Aff request payment 500$    
  1USD = 3RM            
  1HK$ = 2RM            
Insert Data into AffPayout table -->1USD = 1,5HK$            
        
RefIf AffID TransDate CompletedDate IBCCustID UserName IBCUserName Amount AffPayout AffCurrency AffExRate MemberCurrency MemExRate Status    
200000001 1234 03/08/09 04/08/09 1111 12Betaff001 12bet$HKD002001 750 500 3 3 5(HK$) 2 Pending    
        
Inser Data into AffTrans table                 
        
TransID AffID TransDate WinlostDate RefNo Amount Type Currency ExRate Status        
124 1234 03/08/09 04/08/09 200000001 500 202 3 3 Pending        
   
Revisions:      
  
	- 20120115@Peter : Apply Buying Rate for Payout process  
		http://ccs.nexcel.vn/viewtopic.php?f=6&t=8194&p=35675#p35675  
	- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
	- 20130426@LongLuu: Add Japanese Language
    
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
  when 'ko-KR' then N'죄송합니다. 본 계정은 존재하지 않거나 폐쇄된 계정입니다. 관리자에게 문의해주십시요.'    
  when 'ja-JP' then N''
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
  when 'zh-TW' then N'非常抱歉，數額無效。'    
  when 'zh-CN' then N'非常抱歉，数额无效。'    
  when 'th-TH' then N'ขออภัย ระบุจำนวนไม่ถูกต้อง.'     
  when 'es-ES' then N'La cantidad no es válida.'     
  when 'vi-VN' then N'Xin lỗi, số tiền không hợp lệ.'     
  when 'id-ID' then N'Maaf, jumlah tidak valid.'    
  when 'ko-KR' then N'죄송합니다, 잘못된 요청금액.' 
  when 'ja-JP' then N'申し訳ございません。金額が無効です'
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
  when 'zh-TW' then N'您有一項申請在“待處理狀態”，要設置一項新要求，請先取消這暫停而未完成的操作，或等待這次操作完成為止。'    
  when 'zh-CN' then N'你有一项申请在“待处理状态”，要设置一项新要求，请先取消这暂停而未完成的操作，或等待这次操作完成为止。'    
  when 'th-TH' then N'คุณมีรายการแจ้งค้างไว้อยู่แล้ว กรุณายกเลิกรายการก่อนหน้านี้ หรือรอจนกว่ารายการก่อนหน้าทำการสำเร็จแล้วคะ.'    
  when 'es-ES' then N'Tiene una solicitud pendiente. Para crear una nueva solicitud, debe cancelar la que tiene pendiente o esperar hasta que se haya procesado.'    
  when 'vi-VN' then N'Bạn có một yêu cầu đang chờ xử lý. Để tạo một yêu cầu mới, hãy hủy yêu cầu đang chờ xử lý hoặc đợi cho đến khi yêu cầu đó được xử lý.'    
  when 'id-ID' then N'Ada permintaan Anda yang tertunda. Agar dapat membuat permintaan baru, harap batalkan permintaan yang tertunda, atau tunggu sampai permintaan sudah diproses.'    
  when 'ko-KR' then N'보류중인 요청이 있습니다. 새로운 요청을 하기전에 보류중인 요청을 취소 하거나 혹은 보류중인 요청이 처리될때까지 잠시 기다려주시기 바랍니다.'
  when 'ja-JP' then N'保留の依頼があります。新しい依頼をするには保留中の依頼が処理されるのを待つかキャンセルしてください'
  else  N'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'       
    end,     
 @ErrCode = 3003    
 return    
End    
    
--Checking Balance Brought Forward    
if(dbo.Aff_GetAffBalance(@AffID)<=0 or @Amount>dbo.Aff_GetAffBalance(@AffID))    
begin    
   Select @ErrMsg = case @language     
  when 'en-US' then 'Sorry, this Affiliate does not have enough money to withdraw.'    
  when 'zh-TW' then N'非常抱歉，此代理沒有足夠的餘額進行提款。'    
  when 'zh-CN' then N'非常抱歉，此代理没有足够的余额进行提款。'    
  when 'th-TH' then N'ขออภัย บัญชีพันธมิตรไม่มียอดเงินเพียงพอให้ทำรายการถอนคะ.'    
  when 'es-ES' then N'El saldo del afiliado es insuficiente, por lo que no puede retirar fondos.'    
  when 'vi-VN' then N'Xin lỗi, Hội viên này không có đủ tiền để rút.'    
  when 'id-ID' then N'Maaf, Afiliasi ini tidak mempunyai cukup uang untuk ditarik.'    
  when 'ko-KR' then N'되송합니다. 출금을 위한 제휴계좌금액이 부족합니다.'
  when 'ja-JP' then N'申し訳ございません。このアフィリエイトは引出すのに十分な残高がありません'
  else  N'Sorry, this Affiliate does not have enough money to withdraw.'    
    end,     
   @ErrCode = 3004        
  return      
end    
    
--Get all related info and Check Preferred Payment    
declare @PreferredPayment varchar(20), @AffUserName varchar(30),    
   @Player_IBCCustID int, @Player_IBCUserName varchar(30), @Player_Username varchar(30),    
   @Player_Currency int, @PlayerRateOnAff float,@AffCurrencyName varchar(50),@AffCurrency int, @Player_ExRate float, @Aff_ExRate float    
 Select @AffUserName=UserName, @PreferredPayment= PreferredPayment,@Player_IBCCustID=Player_IBCCustID, @Player_Username = Player_Username,@PreferredLanguage=PreferredLanguage    
 from AffDetail (nolock)    
 where AffID=@AffID     
     
 IF @PreferredPayment <> 'Player' --Just support transfer to 12BET player account    
 BEGIN    
  Select @ErrMSg = case @language     
   when 'en-US' then 'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
   when 'zh-TW' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
   when 'zh-CN' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
   when 'th-TH' then N'ขออภัย! ธุรกรรณการเงิน [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] นี้ไม่สามารถใช้ได้ หากต้องการทำธุรกรรมตอนนี้ต้องทำผ่าน '+ ''' บัญชีผู้เล่น 12BET '+ ''' เท่านั้นคะ กรุณาคลิ๊กที่นี่เพื่อเปลี่ยนวิธีการ'    
   when 'es-ES' then N'Lo sentimos. El método de pago [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] no está disponible. En este momento, el único método de pago válido es mediante la cuenta de jugador de 12Bet. Haga clic aquí para realiz  
ar cambios.'    
   when 'vi-VN' then N'Rất tiếc! Phương pháp thanh toán [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] không khả dụng. Tại thời điểm này, chỉ có phương pháp '+ '''Tài khoản Người chơi 12Bet'+''' được hỗ trợ. Hãy nhấp vào đây để thực hiện   
thay đổi.'    
   when 'id-ID' then N'Maaf! Metode pembayaran [Neteller, Transfer Bank,.. - affiliate'+'''s chosen one] tidak tersedia. Pada saat ini, hanya metode '+ '''Rekening Pemain 12Bett'+''' yang didukung. Silakan klik di sini untuk membuat perubahan.'    
   when 'ko-KR' then N'죄송합니다. 선택하신 제휴 출금방법을 사용할수 없습니다. 현재 12bet플레이어 계좌로 출금하는 방법만 사용하실수 있습니다. 여기를 클릭해서 변경할수 있습니다. 여기'
   when 'ja-JP' then N'申し訳ございません。ご指定の支払方法 [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] はご利用いただけません。使用可能な支払方法は '+ '''12Bet Player Account'+'''のみになります。こちらをクリックして変更してください。'
   else  N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
  end,    
   @ErrCode = 3005       
  return    
 END    
 ELSE  
 BEGIN   
 declare @IBCUsername2 varchar(30)  
 select @IBCUsername2 = '12BET$' + @Player_Username   
   
 If Not Exists(Select 1 From bodb02.dbo.Customer (nolock) where Username2 = @IBCUsername2)  
 Begin--Check IBCUsername active or not  
  Select @ErrMSg = case @language     
    when 'en-US' then 'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
    when 'zh-TW' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
    when 'zh-CN' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
    when 'th-TH' then N'ขออภัย บัญชีพันธมิตรนี้ไม่มี บัญชี 12BET ดังกล่าว กรุณาติดต่อฝ่ายบริการ คะ.'   
    when 'vi-VN' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
    when 'id-ID' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
    when 'es-ES' then N'Este afiliado no dispone de nombre de usuario de jugador de 12BET. Póngase en contacto con el administrador.'   
	when 'ko-KR' then N'죄송합니다. 이 제휴는 12bet플레이어 회원의 아이디를 가지고 있지 않습니다. 관계자에게 문의하세요.'
    when 'ja-JP' then N'申し訳ございません。このアフィリエイトは12BETプレーヤー・ユーザー名がありません。管理者にお問い合わせください'
    else  N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'      
   end,    
   @ErrCode = 30010      
  Return  
 End  
   
   
 IF @Player_IBCCustID is null  
 BEGIN  
  SELECT @Player_IBCCustID = CustID from bodb02.dbo.Customer with(nolock) where Username2 = @IBCUsername2  
  UPDATE AffDetail With(Rowlock, Updlock)  
  SET Player_IBCCustID = @Player_IBCCustID  
  WHERE AffID=@AffID   
 END  
 Else--Check whether Player_IBCCustId and Player_Username are matched in the same Account or not, If not => update playercustid = custid of playerusername  
 Begin   
  If Not Exists(Select 1 From bodb02.dbo.Customer c with(nolock) where Username2 = @IBCUsername2 and CustId = @Player_IBCCustID)  
  Begin  
   SELECT @Player_IBCCustID = CustID from bodb02.dbo.Customer with(nolock) where Username2 = @IBCUsername2  
     
   UPDATE AffDetail With(Rowlock, Updlock)  
   SET Player_IBCCustID = @Player_IBCCustID  
   WHERE AffID=@AffID    
  End  
 End  
 END  
    
   Select  @AffCurrency=Currency    
   from AffInfo (nolock)    
   where AffID=@AffID     
    
   Select @AffCurrencyName=Currency, @Aff_ExRate=BuyingRate    
   from Exchange_Current (nolock)    
   where ExchangeID=@AffCurrency    
    
-- check min amount for withdrawing    
 DECLARE @SName varchar(50),@MinAmount money     
 SELECT @MinAmount=cast(SValue as money)     
 from SystemSettings with(nolock)     
 where SName = 'AFF_Min'+ @PreferredPayment + @AffCurrencyName    
    
 IF @MinAmount is not null  and @Amount < @MinAmount     
 BEGIN    
  Select @ErrMSg = case @language     
  when 'en-US' then 'Invalid balance account or either the currency or payment method is not supported.'    
  when 'zh-TW' then N'賬目結算無效或者不支持此幣種或支付方式。'    
  when 'zh-CN' then N'账目结算无效或者不支持此币种或支付方式'    
  when 'th-TH' then N'จำนวนเงิน หรือ สกุลเงิน ที่ระบุไม่ถูกต้อง คะ.'    
  when 'es-ES' then N'El saldo de la cuenta no es válido o la moneda o método de pago no están permitidos.'    
  when 'vi-VN' then N'Tài khoản số dư không hợp lệ hoặc loại tiền tệ hay phương thức thanh toán không được hỗ trợ.'    
  when 'id-ID' then N'Rekening saldo tidak valid, atau mata uangnya, atau metode pembayaran tidak didukung.'    
  when 'ko-KR' then N'유효하지 않은 계좌 잔액 혹은 현재 지원되지않는 출금방법입니다.'
  when 'ja-JP' then N'無効な残高、もしくは指定の通貨、支払方法がサポートされていません'
  else  N'Invalid balance account or either the currency or payment method is not supported.'     
    end,    
   @ErrCode = 3006      
  return    
 END    
    
    
Select @Player_IBCUserName=username,    
    @Player_Currency=currency    
from bodb02.dbo.CustInfo (nolock)    
where  custid=@Player_IBCCustID    
    
select @Player_ExRate=ActualRate    
from bodb02.dbo.Exchange (nolock)    
where exchangeid=@Player_Currency    
    
select @PlayerRateOnAff = BuyingRate2    
from Exchange_Current with (nolock)    
where ExchangeId = @Player_Currency    
    
BEGIN TRANSACTION    
BEGIN TRY    
 declare @RefNo bigint    
 Select @TransDate=current_timestamp    
 Insert into AffPayout(AffID,IBCCustID,UserName,IBCUserName,Amount,AffPayout,AffCurrency,MemberExRate,AffExRate,MemberCurrency,TransDate,Status,CompletedDate)    
 values(@AffID,@Player_IBCCustID,@AffUserName,@Player_IBCUserName,-@Amount,-@Amount/@PlayerRateOnAff,@AffCurrency,@Player_ExRate,@Aff_ExRate,@Player_Currency,@TransDate,'pending',@TransDate)     
   
 Select @RefNo= SCOPE_IDENTITY()    
   
 insert into AffTrans(AffID,TransDate,Amount,Status,Description,Creator,Currency,ActualRate,TransType,RefID,AffExRate,CompletedDate)    
 values(@AffID,@TransDate,-@Amount,'pending','Request payout',@AffID,@AffCurrency,@Player_ExRate,@TransType,@RefNo,@Aff_ExRate,@TransDate)    
 select @TransID=SCOPE_IDENTITY()    
END TRY    
    
BEGIN CATCH    
 rollback transaction     
 Select @ErrMsg = case @language     
    when 'en-US' then 'Insert transaction failed.'    
    when 'zh-TW' then N'插入交易失敗'    
    when 'zh-CN' then N'插入交易失败'    
    when 'th-TH' then N'ระบุรายการเลขที่ไม่ถูกต้อง คะ.'    
    when 'es-ES' then N'No se ha podido completar la transacción.'    
    when 'vi-VN' then N'Chèn giao dịch không thành công.'    
    when 'id-ID' then N'Gagal menyisipkan transaksi.'  
	when 'ko-KR' then N'신청하신 거례가 실패하였습니다.'  
    when 'ja-JP' then N'挿入取引に失敗しました'
    else  N'Insert transaction failed.'     
   end,    
  @ErrCode = 3007    
 return    
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
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestIns] TO [vnteam] AS [dbo]