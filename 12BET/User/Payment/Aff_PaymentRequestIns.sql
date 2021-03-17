/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_PaymentRequestIns]    
	 @AffID					INT,    
	 @Amount				MONEY,     
	 @IP					VARCHAR(20),     
	 @language				VARCHAR(20) = 'en-US',    
	 @PreferredLanguage		VARCHAR(5)='en-US' OUTPUT,    
	 @TransDate				DATETIME = NULL OUTPUT,    
	 @TransID				BIGINT = 0 OUTPUT,    
	 @ErrCode				INT = 0 OUTPUT,    
	 @ErrMsg				NVARCHAR(4000) = '' OUTPUT    
AS    
BEGIN    
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
		- 20210219@Malcolm: Change format when writing logs [RedmineId : #149209]
    
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
	DECLARE @TransType INT    
	SELECT @TransType=202    
	--Checking Affiliate ID    
	IF(NOT EXISTS (SELECT 1 FROM AffInfo (NOLOCK) WHERE affid=@AffID AND Status='approved' AND IsClosed=0 ))    
	BEGIN    
		 SELECT @ErrMsg = CASE @language     
								  WHEN 'en-US' THEN 'Oops, Your account is not existed or closed. Please contact administrator.'     
								  WHEN 'zh-TW' THEN N'Oops, Your account is not existed or closed. Please contact administrator.'    
								  WHEN 'zh-CN' THEN N'Oops, Your account is not existed or closed. Please contact administrator.'    
								  WHEN 'th-TH' THEN N'Oops, Your account is not existed or closed. Please contact administrator.'     
								  WHEN 'es-ES' THEN N'Oops, Your account is not existed or closed. Please contact administrator.'     
								  WHEN 'vi-VN' THEN N'Oops, Your account is not existed or closed. Please contact administrator.' 
								  WHEN 'ko-KR' THEN N'죄송합니다. 본 계정은 존재하지 않거나 폐쇄된 계정입니다. 관리자에게 문의해주십시요.'    
								  WHEN 'ja-JP' THEN N''
								  ELSE  N'Oops, Your account is not existed or closed. Please contact administrator.'        
						  END,   
						  @ErrCode = 3001    
		RETURN     
	END    
	--Checking Amount    
	IF(@Amount<=0)    
	BEGIN    
		  SELECT @ErrMsg = CASE @language     
								  WHEN 'en-US' THEN 'Sorry, amount is invalid.'     
								  WHEN 'zh-TW' THEN N'非常抱歉，數額無效。'    
								  WHEN 'zh-CN' THEN N'非常抱歉，数额无效。'    
								  WHEN 'th-TH' THEN N'ขออภัย ระบุจำนวนไม่ถูกต้อง.'     
								  WHEN 'es-ES' THEN N'La cantidad no es válida.'     
								  WHEN 'vi-VN' THEN N'Xin lỗi, số tiền không hợp lệ.'     
								  WHEN 'id-ID' THEN N'Maaf, jumlah tidak valid.'    
								  WHEN 'ko-KR' THEN N'죄송합니다, 잘못된 요청금액.' 
								  WHEN 'ja-JP' THEN N'申し訳ございません。金額が無効です'
								  ELSE  N'Sorry, amount is invalid.'        
							END,     
				 @ErrCode = 3002    
		   RETURN    
	END    
		-- Checking whether this account has a pending request.    
	IF EXISTS(SELECT 1 FROM AffPayout WITH(NOLOCK) WHERE AffID = @AffID AND Status = 'Pending')    
	BEGIN    
		 SELECT @ErrMsg = CASE @language     
								  WHEN 'en-US' THEN 'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'    
								  WHEN 'zh-TW' THEN N'您有一項申請在“待處理狀態”，要設置一項新要求，請先取消這暫停而未完成的操作，或等待這次操作完成為止。'    
								  WHEN 'zh-CN' THEN N'你有一项申请在“待处理状态”，要设置一项新要求，请先取消这暂停而未完成的操作，或等待这次操作完成为止。'    
								  WHEN 'th-TH' THEN N'คุณมีรายการแจ้งค้างไว้อยู่แล้ว กรุณายกเลิกรายการก่อนหน้านี้ หรือรอจนกว่ารายการก่อนหน้าทำการสำเร็จแล้วคะ.'    
								  WHEN 'es-ES' THEN N'Tiene una solicitud pendiente. Para crear una nueva solicitud, debe cancelar la que tiene pendiente o esperar hasta que se haya procesado.'    
								  WHEN 'vi-VN' THEN N'Bạn có một yêu cầu đang chờ xử lý. Để tạo một yêu cầu mới, hãy hủy yêu cầu đang chờ xử lý hoặc đợi cho đến khi yêu cầu đó được xử lý.'    
								  WHEN 'id-ID' THEN N'Ada permintaan Anda yang tertunda. Agar dapat membuat permintaan baru, harap batalkan permintaan yang tertunda, atau tunggu sampai permintaan sudah diproses.'    
								  WHEN 'ko-KR' THEN N'보류중인 요청이 있습니다. 새로운 요청을 하기전에 보류중인 요청을 취소 하거나 혹은 보류중인 요청이 처리될때까지 잠시 기다려주시기 바랍니다.'
								  WHEN 'ja-JP' THEN N'保留の依頼があります。新しい依頼をするには保留中の依頼が処理されるのを待つかキャンセルしてください'
								  ELSE  N'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'       
						  END,     
				@ErrCode = 3003    
		RETURN    
	END    
    
	--Checking Balance Brought Forward    
	IF(dbo.Aff_GetAffBalance(@AffID)<=0 or @Amount>dbo.Aff_GetAffBalance(@AffID))    
	BEGIN    
		   SELECT @ErrMsg = CASE @language     
								  WHEN 'en-US' THEN 'Sorry, this Affiliate does not have enough money to withdraw.'    
								  WHEN 'zh-TW' THEN N'非常抱歉，此代理沒有足夠的餘額進行提款。'    
								  WHEN 'zh-CN' THEN N'非常抱歉，此代理没有足够的余额进行提款。'    
								  WHEN 'th-TH' THEN N'ขออภัย บัญชีพันธมิตรไม่มียอดเงินเพียงพอให้ทำรายการถอนคะ.'    
								  WHEN 'es-ES' THEN N'El saldo del afiliado es insuficiente, por lo que no puede retirar fondos.'    
								  WHEN 'vi-VN' THEN N'Xin lỗi, Hội viên này không có đủ tiền để rút.'    
								  WHEN 'id-ID' THEN N'Maaf, Afiliasi ini tidak mempunyai cukup uang untuk ditarik.'    
								  WHEN 'ko-KR' THEN N'되송합니다. 출금을 위한 제휴계좌금액이 부족합니다.'
								  WHEN 'ja-JP' THEN N'申し訳ございません。このアフィリエイトは引出すのに十分な残高がありません'
								  ELSE  N'Sorry, this Affiliate does not have enough money to withdraw.'    
							END,     
					@ErrCode = 3004        		
			RETURN      
	END    
    
	--Get all related info and Check Preferred Payment    
	DECLARE @PreferredPayment VARCHAR(20), @AffUserName VARCHAR(30),    
	   @Player_IBCCustID int, @Player_IBCUserName varchar(30), @Player_Username varchar(30),    
	   @Player_Currency int, @PlayerRateOnAff float,@AffCurrencyName varchar(50),@AffCurrency int, @Player_ExRate float, @Aff_ExRate float  
	   
	SELECT @AffUserName=UserName, @PreferredPayment= PreferredPayment,@Player_IBCCustID=Player_IBCCustID, @Player_Username = Player_Username,@PreferredLanguage=PreferredLanguage    
	FROM AffDetail (NOLOCK)    
	WHERE AffID=@AffID     
     
	 IF @PreferredPayment <> 'Player' --Just support transfer to 12BET player account    
	 BEGIN    
		SELECT @ErrMSg = CASE @language     
							   WHEN 'en-US' THEN 'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
							   WHEN 'zh-TW' THEN N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
							   WHEN 'zh-CN' THEN N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
							   WHEN 'th-TH' THEN N'ขออภัย! ธุรกรรณการเงิน [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] นี้ไม่สามารถใช้ได้ หากต้องการทำธุรกรรมตอนนี้ต้องทำผ่าน '+ ''' บัญชีผู้เล่น 12BET '+ ''' เท่านั้นคะ กรุณาคลิ๊กที่นี่เพื่อเปลี่ยนวิธีการ'    
							   WHEN 'es-ES' THEN N'Lo sentimos. El método de pago [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] no está disponible. En este momento, el único método de pago válido es mediante la cuenta de jugador de 12Bet. Haga clic aquí para realizar cambios.'    
							   WHEN 'vi-VN' THEN N'Rất tiếc! Phương pháp thanh toán [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] không khả dụng. Tại thời điểm này, chỉ có phương pháp '+ '''Tài khoản Người chơi 12Bet'+''' được hỗ trợ. Hãy nhấp vào đây để thực hiện thay đổi.'    
							   WHEN 'id-ID' THEN N'Maaf! Metode pembayaran [Neteller, Transfer Bank,.. - affiliate'+'''s chosen one] tidak tersedia. Pada saat ini, hanya metode '+ '''Rekening Pemain 12Bett'+''' yang didukung. Silakan klik di sini untuk membuat perubahan.'    
							   WHEN 'ko-KR' THEN N'죄송합니다. 선택하신 제휴 출금방법을 사용할수 없습니다. 현재 12bet플레이어 계좌로 출금하는 방법만 사용하실수 있습니다. 여기를 클릭해서 변경할수 있습니다. 여기'
							   WHEN 'ja-JP' THEN N'申し訳ございません。ご指定の支払方法 [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] はご利用いただけません。使用可能な支払方法は '+ '''12Bet Player Account'+'''のみになります。こちらをクリックして変更してください。'
							   ELSE  N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''12Bet Player Account'+''' method is supported. Please click here to make a change.'    
						 END,    
				@ErrCode = 3005       
		RETURN    
	 END    
	 ELSE  
	 BEGIN   
		 DECLARE @IBCUsername2 VARCHAR(30)  
		 SELECT @IBCUsername2 = '12BET$' + @Player_Username   
   
		 IF NOT EXISTS(SELECT 1 FROM bodb02.dbo.Customer (NOLOCK) WHERE Username2 = @IBCUsername2)  
		 BEGIN--Check IBCUsername active or not  
			SELECT @ErrMSg = CASE @language     
									WHEN 'en-US' THEN 'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
									WHEN 'zh-TW' THEN N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
									WHEN 'zh-CN' THEN N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
									WHEN 'th-TH' THEN N'ขออภัย บัญชีพันธมิตรนี้ไม่มี บัญชี 12BET ดังกล่าว กรุณาติดต่อฝ่ายบริการ คะ.'   
									WHEN 'vi-VN' THEN N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
									WHEN 'id-ID' THEN N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
									WHEN 'es-ES' THEN N'Este afiliado no dispone de nombre de usuario de jugador de 12BET. Póngase en contacto con el administrador.'   
									WHEN 'ko-KR' THEN N'죄송합니다. 이 제휴는 12bet플레이어 회원의 아이디를 가지고 있지 않습니다. 관계자에게 문의하세요.'
									WHEN 'ja-JP' THEN N'申し訳ございません。このアフィリエイトは12BETプレーヤー・ユーザー名がありません。管理者にお問い合わせください'
									ELSE  N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'      
								   END,    
					@ErrCode = 30010      
			RETURN  
		 END  
   
		 IF @Player_IBCCustID is null  
		 BEGIN  
			  SELECT @Player_IBCCustID = CustID from bodb02.dbo.Customer with(nolock) where Username2 = @IBCUsername2  
			  UPDATE AffDetail With(Rowlock, Updlock)  
			  SET Player_IBCCustID = @Player_IBCCustID  
			  WHERE AffID=@AffID   
		 END  
		 Else--Check whether Player_IBCCustId and Player_Username are matched in the same Account or not, If not => update playercustid = custid of playerusername  
		 BEGIN   
			IF NOT EXISTS(SELECT 1 FROM bodb02.dbo.Customer c WITH(NOLOCK) WHERE Username2 = @IBCUsername2 and CustId = @Player_IBCCustID)  
			BEGIN  
				SELECT @Player_IBCCustID = CustID from bodb02.dbo.Customer with(nolock) where Username2 = @IBCUsername2  
     
			    UPDATE AffDetail WITH(ROWLOCK, UPDLOCK)  
			    SET Player_IBCCustID = @Player_IBCCustID  
			    WHERE AffID=@AffID    
			END  
		 END  
	END  
    
	SELECT  @AffCurrency=Currency    
	FROM AffInfo (NOLOCK)    
	WHERE AffID=@AffID     
    
	SELECT @AffCurrencyName=Currency, @Aff_ExRate=BuyingRate    
	FROM Exchange_Current (NOLOCK)    
	WHERE ExchangeID=@AffCurrency    
    
	-- check min amount for withdrawing    
	DECLARE @SName VARCHAR(50),@MinAmount MONEY     
	SELECT @MinAmount=cast(SValue AS MONEY)     
	FROM SystemSettings WITH(NOLOCK)     
	WHERE SName = 'AFF_Min'+ @PreferredPayment + @AffCurrencyName    
    
	IF @MinAmount IS NOT NULL AND @Amount < @MinAmount     
	BEGIN    
	  SELECT @ErrMSg = CASE @language     
							  WHEN 'en-US' THEN 'Invalid balance account or either the currency or payment method is not supported.'    
							  WHEN 'zh-TW' THEN N'賬目結算無效或者不支持此幣種或支付方式。'    
							  WHEN 'zh-CN' THEN N'账目结算无效或者不支持此币种或支付方式'    
							  WHEN 'th-TH' THEN N'จำนวนเงิน หรือ สกุลเงิน ที่ระบุไม่ถูกต้อง คะ.'    
							  WHEN 'es-ES' THEN N'El saldo de la cuenta no es válido o la moneda o método de pago no están permitidos.'    
							  WHEN 'vi-VN' THEN N'Tài khoản số dư không hợp lệ hoặc loại tiền tệ hay phương thức thanh toán không được hỗ trợ.'    
							  WHEN 'id-ID' THEN N'Rekening saldo tidak valid, atau mata uangnya, atau metode pembayaran tidak didukung.'    
							  WHEN 'ko-KR' THEN N'유효하지 않은 계좌 잔액 혹은 현재 지원되지않는 출금방법입니다.'
							  WHEN 'ja-JP' THEN N'無効な残高、もしくは指定の通貨、支払方法がサポートされていません'
							  ELSE  N'Invalid balance account or either the currency or payment method is not supported.'     
						END,    
			@ErrCode = 3006      
		RETURN    
	 END    
     
	SELECT @Player_IBCUserName=username,    
		@Player_Currency=currency    
	FROM bodb02.dbo.CustInfo (NOLOCK)    
	WHERE  custid=@Player_IBCCustID    
    
	SELECT @Player_ExRate=ActualRate    
	FROM bodb02.dbo.Exchange (NOLOCK)    
	WHERE exchangeid=@Player_Currency    
    
	SELECT @PlayerRateOnAff = BuyingRate2    
	FROM Exchange_Current WITH (NOLOCK)    
	WHERE ExchangeId = @Player_Currency    
    
	BEGIN TRANSACTION    
	BEGIN TRY    
		 DECLARE @RefNo BIGINT    
		 SELECT @TransDate=CURRENT_TIMESTAMP    
		 INSERT INTO AffPayout(AffID,IBCCustID,UserName,IBCUserName,Amount,AffPayout,AffCurrency,MemberExRate,AffExRate,MemberCurrency,TransDate,Status,CompletedDate)    
		 VALUES(@AffID,@Player_IBCCustID,@AffUserName,@Player_IBCUserName,-@Amount,-@Amount/@PlayerRateOnAff,@AffCurrency,@Player_ExRate,@Aff_ExRate,@Player_Currency,@TransDate,'pending',@TransDate)     
   
		 SELECT @RefNo= SCOPE_IDENTITY()    
   
		 INSERT INTO AffTrans(AffID,TransDate,Amount,Status,Description,Creator,Currency,ActualRate,TransType,RefID,AffExRate,CompletedDate)    
		 VALUES(@AffID,@TransDate,-@Amount,'pending','Request payout',@AffID,@AffCurrency,@Player_ExRate,@TransType,@RefNo,@Aff_ExRate,@TransDate)    
		 SELECT @TransID=SCOPE_IDENTITY()    
	END TRY    
    
	BEGIN CATCH    
		ROLLBACK TRANSACTION     
			 SELECT @ErrMsg = CASE @language     
									WHEN 'en-US' THEN 'Insert transaction failed.'    
									WHEN 'zh-TW' THEN N'插入交易失敗'    
									WHEN 'zh-CN' THEN N'插入交易失败'    
									WHEN 'th-TH' THEN N'ระบุรายการเลขที่ไม่ถูกต้อง คะ.'    
									WHEN 'es-ES' THEN N'No se ha podido completar la transacción.'    
									WHEN 'vi-VN' THEN N'Chèn giao dịch không thành công.'    
									WHEN 'id-ID' THEN N'Gagal menyisipkan transaksi.'  
									WHEN 'ko-KR' THEN N'신청하신 거례가 실패하였습니다.'  
									WHEN 'ja-JP' THEN N'挿入取引に失敗しました'
									ELSE  N'Insert transaction failed.'     
							  END,    
					@ErrCode = 3007    
		RETURN  
		RETURN
	END CATCH    
    
	COMMIT TRANSACTION     
     
    
	--Write the log     
	DECLARE @LogData NVARCHAR(MAX),@SPName varchar(100)       

	SELECT @LogData = CONVERT(NVARCHAR(MAX), (SELECT @TransID AS '@TransactionId', @Amount AS '@Amount' FOR XML PATH('row'), ROOT('root'))), @SPName=OBJECT_NAME(@@ProcID)    
     
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog    
			 @SPName = @SPName
			 ,@UserId = @AffID
			 ,@AffId = @AffID
			 ,@OldData = NULL
			 ,@NewData = @LogData
			 ,@IP = @IP	
  
END
GO
