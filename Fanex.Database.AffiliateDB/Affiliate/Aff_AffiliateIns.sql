/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 11/3/2009 5:46:27 PM ******/  
ALTER PROCEDURE [dbo].[Aff_AffiliateIns]   
 @AffId int OUTPUT, 
 @AffType tinyint = 1,   
 @firstname nvarchar(50),    
 @lastname nvarchar(50),    
 @Gender bit = null,    
 @email nvarchar(50),    
 @phone nvarchar(50),    
 @mobilephone nvarchar(50),    
  
 @address nvarchar(80),    
 @city nvarchar(50),     
 @state nvarchar(50),    
 @postal nvarchar(50),    
 @country nvarchar(50),     
 @emailformat bit = null,  
 @Currency int,  
 --------------------------------------------------     
 @SiteURL varchar(100),     
 @MoreSiteURLs varchar(1000) = NULL,    
 @PreferredLanguage varchar(5),    
 @PreferredPayment varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque    
 @Player_Username varchar(30),    
 @Neteller_AccountID varchar(50) = null,    
 @Moneybookers_Email varchar(50) = null,    
 @Wire_BankName  nvarchar(100) = null,    
 @Wire_BankAddress nvarchar(200) = null,    
 @Wire_SwiftCode  nvarchar(20) = null,    
 @Wire_AccountName nvarchar(100) = null,     
 @Wire_AccountNo  varchar(50) = null,    
 @Cheque_FullName nvarchar(200) = null,    
 @Cheque_Address  nvarchar(200) = null,    
 @Cheque_City  nvarchar(50) = null,    
 @Cheque_State  nvarchar(50) = null,    
 @Cheque_Postal  nvarchar(50) = null,    
 @Cheque_Country  varchar(50) = null,     
 --------------------------------------------------       
 @Question   nvarchar(120),    
 @Answer    nvarchar(120),    
 @IP varchar(20),    
 @Browser varchar(100)='',
 @language varchar(5) = 'en-US',    
 @username varchar(30) = NULL OUTPUT,    
 @ErrCode int = 0 OUTPUT,    
 @ErrMsg nvarchar(200) = '' OUTPUT    
AS  
/*      
Created:     
Task : Register new Affiliate    
DB: DB052.Affiliate_ZZun  
Original: [Aff_AffiliateIns]    
Revisions:      
  
Param's Explanation:      
• @ErrCode:      
    = 0: Create agent successfully.      
    > 0: Specific Error.      
        
• @ErrMsg: Error description.      
*/     
SET NOCOUNT ON  
  
/*IF Exists(Select 1 From AffInfo with (nolock) where UserName2=@UserName2)    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then N'Nickname has been used. Please choose another one!'  
      when 'zh-TW' then N'Nickname has been used. Please choose another one!'  
      when 'zh-CN' then N'Nickname has been used. Please choose another one!'  
      when 'th-TH' then N'Nickname has been used. Please choose another one!ะ'  
      when 'es-ES' then N'Nickname has been used. Please choose another one!'  
      when 'vi-VN' then N'Nickname đã được sử dụng. Vui lòng chọn Nickname khác!'  
      when 'id-ID' then N'Nickname has been used. Please choose another one!'  
      else N'Nickname has been used. Please choose another one!'    
      end, @ErrCode = 1012  
 return  
END  */  
  
  
IF Exists(Select 1 From AffInfo with (nolock) where email=@email and Status <> 'Disapproved')    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Email Address has been used. Please choose another one!'  
      when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'  
      when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'  
      when 'th-TH' then N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ'  
      when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'  
      when 'vi-VN' then N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'  
      when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'  
      else N'Email Address has been used. Please choose another one!'    
      end, @ErrCode = 1002  
 return  
END     
  
  
--Generate username-----------------    
Exec Aff_GenUsername @username = @username OUTPUT    
  
if exists(select 1 from AffInfo with (nolock) where username = @username)    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Invalid affiliate information.'  
      when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'  
      when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'  
      when 'th-TH' then N'ระบุข้อมูลพันธมิตรไม่ถูกต้อง.'   
      when 'es-ES' then N'La información de afiliación no es válida.'   
      when 'vi-VN' then N'Thông tin hội viên không hợp lệ.'   
      when 'id-ID' then N'Informasi afiliasi tidak valid.'   
      else N'Invalid affiliate information.'       
      end, @ErrCode = 1004  
 return  
END   
--End generate username-----------------    
  
  
  
  
Insert into AffInfo(  
 [UserName]  
 --,[UserName2]  
 ,[FirstName]  
 ,[LastName]  
 ,[Status]  
 ,[IsClosed]  
 ,[Currency]  
 ,[RegisteredDate]  
 ,[Email]  
 ,[Password]  
 ,[IsLocked]
 ,[AffType])  
Values  
(  
 @Username  
 --,@Username2  
 ,@FirstName  
 ,@LastName  
 ,'Pending'  
 ,0  
 ,@Currency  
 ,GetDate()  
 ,@Email  
 ,''  
 ,0  
 ,@AffType
)  
  
if @@error <> 0  
BEGIN    
 SELECT @ErrMsg = case @Language     
    when 'en-US' then 'Create customer failed. Please try again.'    
    when 'zh-TW' then N'新增会员不成功，请重新尝试.'    
    when 'zh-CN' then N'新增會員不成功,請重新再試.'    
    when 'th-TH' then N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'        
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'    
    when 'KO' then N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'    
    when 'vi-VN' then N'Tạo khách hàng không thành công. Hãy thử lại.'    
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'    
    else N'Create customer failed. Please try again.'    
   end,    
 @ErrCode = 114    
      
 -- ROLLBACK MANUALLY  `  
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId    
      
 return    
END    
  
select @AffId = @@IDENTITY  
  
Insert into AffDetail(  
 [AffID]  
 ,[UserName]  
 ,[SiteURL]  
 ,[MoreSiteURLs]  
 ,[PreferredLanguage]  
 ,[Gender]  
 ,[Address]  
 ,[Postal]  
 ,[City]  
 ,[State]  
 ,[CountryID]  
 ,[Phone]  
 ,[MobilePhone]  
 ,[Fax]  
 ,[Question]  
 ,[Answer]  
 ,[PreferredPayment]   
 ,[Player_Username]  
 ,[Neteller_AccountID]  
 ,[Moneybookers_Email]  
 ,[Wire_BankName]  
 ,[Wire_BankAddress]  
 ,[Wire_SwiftCode]  
 ,[Wire_AccountName]  
 ,[Wire_AccountNo]  
 ,[Cheque_FullName]  
 ,[Cheque_Address]  
 ,[Cheque_City]  
 ,[Cheque_State]  
 ,[Cheque_Postal]  
 ,[Cheque_Country]  
 ,[MailOption]  
)  
Values  
(  
 @AFfId  
 ,@Username  
 ,@SiteURL  
 ,@MoreSiteURLs  
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
 ,@Player_Username  
 ,@Neteller_AccountID  
 ,@Moneybookers_Email  
 ,@Wire_BankName  
 ,@Wire_BankAddress  
 ,@Wire_SwiftCode  
 ,@Wire_AccountName  
 ,@Wire_AccountNo  
 ,@Cheque_FullName  
 ,@Cheque_Address  
 ,@Cheque_City  
 ,@Cheque_State  
 ,@Cheque_Postal  
 ,@Cheque_Country  
 ,@EmailFormat  
)  
if @@error <> 0  
BEGIN    
 SELECT @ErrMsg = case @Language     
    when 'en-US' then 'Create customer failed. Please try again.'    
    when 'zh-TW' then N'新增会员不成功，请重新尝试.'    
    when 'zh-CN' then N'新增會員不成功,請重新再試.'    
    when 'th-TH' then N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'        
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'    
    when 'KO' then N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'    
    when 'vi-VN' then N'Tạo khách hàng không thành công. Hãy thử lại.'    
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'    
    else N'Create customer failed. Please try again.'    
   end,    
 @ErrCode = 111    
      
 -- ROLLBACK MANUALLY  `  
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId    
 Delete From AffDetail With (ROWLOCK) Where AffId = @AffId    
      
 return    
END    
  
  
Declare @LogData varchar(5000), @SPName varchar(100)   
select @SPName = OBJECT_NAME(@@ProcID)  
    
Select @LogData = 'Add new Affifilate  
firstname='+ dbo.Aff_ToString(@firstname) + ',  
lastname'+ dbo.Aff_ToString(@lastname) + ',  
Gender='+ dbo.Aff_ToString(@Gender) + ',  
country='+ dbo.Aff_ToString(@country) + ',  
email='+ dbo.Aff_ToString(@email) + ',  
phone='+ dbo.Aff_ToString(@phone) + ',  
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',  
address='+ dbo.Aff_ToString(@address) + ',  
city='+ dbo.Aff_ToString(@city) + ',  
state='+ dbo.Aff_ToString(@state) + ',  
postal='+ dbo.Aff_ToString(@postal) + ',  
Currency='+ dbo.Aff_ToString(@Currency) + ',  
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',  
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',  
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',  
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',  
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',  
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',  
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',  
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',  
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',  
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',  
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',  
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',  
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',  
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',  
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',  
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@AffID,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData  
 
 GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateIns] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateIns] TO [VNTeam]