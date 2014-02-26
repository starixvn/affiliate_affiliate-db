ALTER PROCEDURE [dbo].[Aff_AffiliateIns] 
	@AffMaster VARCHAR(50)--'12BetAff'  
	,@AffType TINYINT = 0	-- 0, 1: Asia Affiliate; 2: EU Affiliate
	,@AffId INT OUTPUT
	,@firstname NVARCHAR(50)
	,@lastname NVARCHAR(50)
	,@Gender BIT = NULL
	,@email NVARCHAR(50)
	,@phone NVARCHAR(50)
	,@mobilephone NVARCHAR(50)
	,@address NVARCHAR(80)
	,@city NVARCHAR(50)
	,@state NVARCHAR(50)
	,@postal NVARCHAR(50)
	,@country NVARCHAR(50)
	,@emailformat BIT = 0
	--------------------------------------------------     
	,@SiteURL VARCHAR(100)
	,@MoreSiteURLs VARCHAR(1000) = NULL
	,@NoSiteDesc NVARCHAR(1000) = NULL
	,@PreferredLanguage VARCHAR(5)
	,@PreferredPayment VARCHAR(20) --Player, Neteller, Moneybookers, Wire, Cheque    
	,@Player_Username VARCHAR(30)
	,@Question NVARCHAR(120)
	,@Answer NVARCHAR(120)
	,@IP VARCHAR(20)
	,@Browser VARCHAR(100) = ''
	--------------------------------------------------    
	,@language VARCHAR(2) = 'en-US'
	,@username VARCHAR(30) = NULL OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*      
Created:     
Task : Register new Affiliate    
DB: DB052.Affiliate_12BET  
Original: [Aff_AffiliateIns]    
Revisions:      
 - 20111208@Johnny: Affiliate amendment of signup page http://ccs.nexcel.vn/viewtopic.php?f=6&t=5950  
 - 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
 - 20130426@LongLuu: Add Japanese Language
 - 20140214@BrianDinh: Add AffType
  
Param's Explanation:      
• @ErrCode:      
 = 0: Create agent successfully.      
 > 0: Specific Error.      
     
• @ErrMsg: Error description.      
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS (
			SELECT 1
			FROM AffInfo WITH (NOLOCK)
			WHERE email = @email
				AND STATUS <> 'Disapproved'
			)
	BEGIN
		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Email Address has been used. Please choose another one!'
				WHEN 'zh-TW' THEN N'此郵箱地址已被使用，請選用其他郵箱地址。'
				WHEN 'zh-CN' THEN N'此邮箱地址已被使用，请选用其他邮箱地址。'
				WHEN 'th-TH' THEN N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ'
				WHEN 'es-ES' THEN N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'
				WHEN 'vi-VN' THEN N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'
				WHEN 'id-ID' THEN N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'
				WHEN 'ko-KR' THEN N'이미 사용된 이메일입니다. 다른 이메일을 사용해 주십시오.'
				WHEN 'ja-JP' THEN N'このメールアドレスは既に使用されています。別のアドレスを使用してください'
				ELSE N'Email Address has been used. Please choose another one!'
				END
			,@ErrCode = 1002

		RETURN
	END

	DECLARE @Player_IBCCustId INT

	SELECT @Player_IBCCustId = CustId
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE UserName2 = '12Bet$' + @Player_Username

	--Generate username-----------------    
	EXEC Aff_GenUsername @AffPrefix = @AffMaster
		,@username = @username OUTPUT

	IF EXISTS (
			SELECT 1
			FROM AffInfo WITH (NOLOCK)
			WHERE username = @username
			)
	BEGIN
		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Invalid affiliate information.'
				WHEN 'zh-TW' THEN N'此郵箱地址已被使用，請選用其他郵箱地址。'
				WHEN 'zh-CN' THEN N'此邮箱地址已被使用，请选用其他邮箱地址。'
				WHEN 'th-TH' THEN N'ระบุข้อมูลพันธมิตรไม่ถูกต้อง.'
				WHEN 'es-ES' THEN N'La información de afiliación no es válida.'
				WHEN 'vi-VN' THEN N'Thông tin hội viên không hợp lệ.'
				WHEN 'id-ID' THEN N'Informasi afiliasi tidak valid.'
				WHEN 'ko-KR' THEN N'유효하지 않은 제휴정보.'
				WHEN 'ja-JP' THEN N'アフィリエイト情報が無効です'
				ELSE N'Invalid affiliate information.'
				END
			,@ErrCode = 1004

		RETURN
	END

	--End generate username-----------------    
	INSERT INTO AffInfo (
		[UserName]
		,[FirstName]
		,[LastName]
		,[Status]
		,[IsClosed]
		,[Currency]
		,[RegisteredDate]
		,[Email]
		,[Password]
		,[AffType]
		)
	VALUES (
		@Username
		,@FirstName
		,@LastName
		,'Pending'
		,0
		,3
		,GetDate()
		,@Email
		,''
		,@AffType
		)

	IF @@error <> 0
	BEGIN
		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Create customer failed. Please try again.'
				WHEN 'zh-TW' THEN N'新增会员不成功，请重新尝试.'
				WHEN 'zh-CN' THEN N'新增會員不成功,請重新再試.'
				WHEN 'th-TH' THEN N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'
				WHEN 'es-ES' THEN N'No se ha podido crear el cliente. Vuelva a intentarlo.'
				WHEN 'KO' THEN N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'
				WHEN 'vi-VN' THEN N'Tạo khách hàng không thành công. Hãy thử lại.'
				WHEN 'id-ID' THEN N'Gagal membuat pelanggan. Harap coba lagi.'
				WHEN 'ko-KR' THEN N'고객 생성에 실패했습니다. 다시 시도해 주세요.'
				WHEN 'ja-JP' THEN N'顧客作成に失敗しました。もう一度やり直してください'
				ELSE N'Create customer failed. Please try again.'
				END
			,@ErrCode = 114

		-- ROLLBACK MANUALLY  `  
		DELETE
		FROM AffInfo WITH (ROWLOCK)
		WHERE AffId = @AffId

		RETURN
	END

	SELECT @AffId = @@IDENTITY

	INSERT INTO AffDetail (
		[AffID]
		,[UserName]
		,[SiteURL]
		,[MoreSiteURLs]
		,[NoSiteDesc]
		,[PreferredLanguage]
		,[Gender]
		,[Address]
		,[Postal]
		,[City]
		,[State]
		,[Country]
		,[Phone]
		,[MobilePhone]
		,[Fax]
		,[Question]
		,[Answer]
		,[PreferredPayment]
		,[Player_IBCCustID]
		,[Player_Username]
		,[MailOption]
		)
	VALUES (
		@AFfId
		,@Username
		,@SiteURL
		,@MoreSiteURLs
		,@NoSiteDesc
		,@PreferredLanguage
		,@Gender
		,@address
		,@postal
		,@city
		,@state
		,@country
		,@phone
		,@mobilephone
		,''
		,@Question
		,@Answer
		,@PreferredPayment
		,@Player_IBCCustId
		,@Player_Username
		,@EmailFormat
		)

	IF @@error <> 0
	BEGIN
		SELECT @ErrMsg = CASE @Language
				WHEN 'en-US' THEN 'Create customer failed. Please try again.'
				WHEN 'zh-TW' THEN N'新增会员不成功，请重新尝试.'
				WHEN 'zh-CN' THEN N'新增會員不成功,請重新再試.'
				WHEN 'th-TH' THEN N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'
				WHEN 'es-ES' THEN N'No se ha podido crear el cliente. Vuelva a intentarlo.'
				WHEN 'KO' THEN N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'
				WHEN 'vi-VN' THEN N'Tạo khách hàng không thành công. Hãy thử lại.'
				WHEN 'id-ID' THEN N'Gagal membuat pelanggan. Harap coba lagi.'
				WHEN 'ko-KR' THEN N'고객 생성에 실패했습니다. 다시 시도해 주세요.'
				WHEN 'ja-JP' THEN N'顧客作成に失敗しました。もう一度やり直してください'
				ELSE N'Create customer failed. Please try again.'
				END
			,@ErrCode = 111

		-- ROLLBACK MANUALLY  `  
		DELETE
		FROM AffInfo WITH (ROWLOCK)
		WHERE AffId = @AffId

		DELETE
		FROM AffDetail WITH (ROWLOCK)
		WHERE AffId = @AffId

		RETURN
	END

	DECLARE @LogData VARCHAR(5000)
		,@SPName VARCHAR(100)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = 'Add new Affifilate  
		firstname=' + dbo.Aff_ToString(@firstname) + ',  
		lastname' + dbo.Aff_ToString(@lastname) + ',  
		Gender=' + dbo.Aff_ToString(@Gender) + ',  
		country=' + dbo.Aff_ToString(@country) + ',  
		email=' + dbo.Aff_ToString(@email) + ',  
		phone=' + dbo.Aff_ToString(@phone) + ',  
		mobilephone=' + dbo.Aff_ToString(@mobilephone) + ',  
		address=' + dbo.Aff_ToString(@address) + ',  
		city=' + dbo.Aff_ToString(@city) + ',  
		state=' + dbo.Aff_ToString(@state) + ',  
		postal=' + dbo.Aff_ToString(@postal) + ',  
		SiteURL=' + dbo.Aff_ToString(@SiteURL) + ',  
		MoreSiteURLs=' + dbo.Aff_ToString(@MoreSiteURLs) + ',  
		NoSiteDesc=' + dbo.Aff_ToString(@NoSiteDesc) + ',  
		PreferredPayment=' + dbo.Aff_ToString(@PreferredPayment) + ',  
		PreferredLanguage=' + dbo.Aff_ToString(@PreferredLanguage) + ',  
		Player_Username=' + dbo.Aff_ToString(@Player_Username) + ',  
		language=' + dbo.Aff_ToString(@language)

	EXEC [dbo].[Aff_WriteLog] @Creator = @AffID
		,@AffID = @AffID
		,@Typename = 'UserInfo'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateIns] TO [bodbDownlineNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateIns] TO [VNTeam]
