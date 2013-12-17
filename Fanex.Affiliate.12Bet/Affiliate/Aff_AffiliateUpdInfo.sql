/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdInfo_xpre    Script Date: 1/3/2012 4:16:35 AM ******/  
/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdInfo    Script Date: 12/27/2011 9:55:30 AM ******/  
Alter PROC [dbo].[Aff_AffiliateUpdInfo]  
 @AffId int ,  
 @userid int,  
 @firstname nvarchar(50) = NULL,  
 @lastname nvarchar(50) = NULL,  
 @Gender bit = null,  
 @country nvarchar(50) = NULL,  
 @email nvarchar(50)=NULL,  
 @password varchar(40)=NULL,  
 @phone nvarchar(50)=NULL,  
 @mobilephone nvarchar(50)=NULL,  
 @address nvarchar(80)=NULL,  
 @city nvarchar(50)=NULL,   
 @state nvarchar(50)=NULL,  
 @postal nvarchar(50)=NULL,  
 @emailformat bit = null,  
  --Add for Personalized Site  
 @IsPageEnabled bit=0,  
 @Level int=0,    
 ---------------------------------------------------------------------------------  
 -- Parameter for Affiliate info(use for update/insert data to DB03)  
 @SiteURL varchar(100)=NULL,  
 @MoreSiteURLs varchar(1000) = NULL,  
 @NoSiteDesc varchar(1000) = NULL,  
 @PreferredLanguage varchar(11)=NULL,  
 @PreferredPayment varchar(20)='Player', --Player, Neteller, Moneybookers, Wire, Cheque  
 @Player_Username varchar(30)=NULL,  
 @Neteller_AccountID varchar(50)=NULL,  
 @Moneybookers_Email varchar(50)=NULL,  
 @Wire_BankName  nvarchar(100)=NULL,  
 @Wire_BankAddress nvarchar(200)=NULL,  
 @Wire_SwiftCode  nvarchar(20)=NULL,  
 @Wire_AccountName nvarchar(100)=NULL,   
 @Wire_AccountNo  varchar(50)=NULL,  
 @Cheque_FullName nvarchar(200)=NULL,  
 @Cheque_Address  nvarchar(200)=NULL,  
 @Cheque_City  nvarchar(50)=NULL,  
 @Cheque_State  nvarchar(50)=NULL,  
 @Cheque_Postal  nvarchar(50)=NULL,  
 @Cheque_Country  varchar(50)=NULL,  
 ---------------------------------------------------------------------------------  
 @language varchar(20) = 'es-ES',  
 @IP varchar(20),  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*Updated: 20090324@VinhTrinh  
Task : Update affiliate infor.  
DB: DB052.Affiliate_12BET  
Original : [Aff_AffiliateUpdInfo]  
Revisions:  
 Peter@20100209 : Check If Admin update Player_UserName, we must make sure there is no pending payment request.  
   
Param's Explanation:  
• @AffId : Affiliate custid  
• @userid : user update.  
• @firstname : update firstname.  
....  
*/  
  
SET NOCOUNT ON  
  
--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------  
if @AffId <> @userid  
Begin  
 EXEC [dbo].[Aff_Con_CheckPermission]   
  @custid=@UserID,@funcname='[Affiliate]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
   
 If @ErrCode <> 0  
  RETURN  
End  
  
--Check If we change player_username  
  
if (@Player_Username <> (Select Player_UserName from AffDetail with (nolock) where AffId=@AffID)  
  and exists (Select 1 from AffPayout with (nolock) where AffID=@AffID and Status='pending')  
 )  
   
 BEGIN  
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'zh-TW' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'zh-CN' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'th-TH' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'es-ES' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'vi-VN' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'id-ID' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!' 
	  when 'ko-KR' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'   
      else N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      end, @ErrCode = 1001  
 return  
   
 END     
-----------------------------------------------  
  
--Check duplicate Email   
  
IF Exists(Select 1 From AffInfo a with(nolock) where a.email=@email and a.AffId <> @AffId and a.Status <> 'Disapproved')  
BEGIN  
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Email Address has been used. Please choose another one!'  
      when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'  
      when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'  
      when 'th-TH' then N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ!'  
      when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'  
      when 'vi-VN' then N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'  
      when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'  
	  when 'ko-KR' then N'이미 사용된 이메일입니다. 다른 이메일을 사용해 주십시오.'
      else N'Email Address has been used. Please choose another one!'  
      end, @ErrCode = 1002  
 return  
END   
  
Begin Transaction  
  
UPDATE AffInfo with(rowlock,updlock)   
SET firstname = isnull(@firstname,firstname),  
 lastname = isnull(@lastname,lastname),  
 email = isnull(@email,email),  
 Password = isnull(@password,Password),  
 IsPageEnabled = isnull(@IsPageEnabled,IsPageEnabled),  
 [Level] = isnull(@Level,[Level])  
   
WHERE AffId = @AffId  
  
IF @@error<>0   
BEGIN  
 SELECT @ErrMsg = CASE @Language   
      WHEN 'es-ES' THEN 'Invalid user information. Update process is unsuccessful!'  
      WHEN 'zh-TW' THEN N'用戶信息無效，更新失敗。'  
      WHEN 'zh-CN' THEN N'用户信息无效，更新失败。'  
      WHEN 'J' THEN N'Invalid user information. Update process is unsuccessful!'  
      WHEN 'th-TH' THEN N'ข้อมูลผู้ใช้ไม่ถุกต้อง อัพเดทข้อมูลไม่สำเร็จคะ!'  
      WHEN 'es-ES' THEN N'La información de usuario no es válida. No se ha podido completar el proceso de actualización.'        
      WHEN 'vi-VN' THEN N'Thông tin người dùng không hợp lệ. Quá trình cập nhật không thành công!'  
      WHEN 'id-ID' THEN N'Informasi pengguna tidak valid. Proses pembaruan tidak berhasil!'    
	  when 'ko-KR' then N'잘못된 사용자 정보. 업데이트에 실패했습니다. '    
      ELSE N'Invalid user information. Update process is unsuccessful!'  
     END, @ErrCode = 1004        
 RollBack Transaction  
 RETURN  
END  
  
Declare @Player_IBCCustId int  
select @Player_IBCCustId = CustId  
from bodb02.dbo.Customer with (nolock)  
where UserName2 = '12Bet$' + @Player_Username  
  
UPDATE AffDetail  with(rowlock,updlock)   
SET    
 Gender = isnull(@Gender,Gender),  
 country = isnull(@country,country),  
 phone = isnull(@phone,phone),  
 mobilephone = isnull(@mobilephone,mobilephone),  
 address = isnull(@address,address),  
 city = isnull(@city,city),  
 state = isnull(@state,state),   
 postal = isnull(@postal,postal),  
 SiteURL=isnull(@SiteURL,SiteURL),    
 MoreSiteURLs=isnull(@MoreSiteURLs, MoreSiteURLs),  
 NoSiteDesc =isnull(@NoSiteDesc, NoSiteDesc),   
 PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage),  
 PreferredPayment=@PreferredPayment,   
 Player_IBCCustID=@Player_IBCCustId,   
 Player_Username=isnull(@Player_Username,Player_Username),    
 Neteller_AccountID=isnull(@Neteller_AccountID,Neteller_AccountID),    
 Moneybookers_Email=isnull(@Moneybookers_Email,Moneybookers_Email),    
 Wire_BankName=isnull(@Wire_BankName,Wire_BankName),    
 Wire_BankAddress=isnull(@Wire_BankAddress,Wire_BankAddress),    
 Wire_SwiftCode=isnull(@Wire_SwiftCode,Wire_SwiftCode),    
 Wire_AccountName=isnull(@Wire_AccountName,Wire_AccountName),    
 Wire_AccountNo=isnull(@Wire_AccountNo,Wire_AccountNo),    
 Cheque_FullName=isnull(@Cheque_FullName,Cheque_FullName),    
 Cheque_Address=isnull(@Cheque_Address,Cheque_Address),    
 Cheque_City=isnull(@Cheque_City,Cheque_City),    
 Cheque_State=isnull(@Cheque_State,Cheque_State),    
 Cheque_Postal=isnull(@Cheque_Postal,Cheque_Postal),    
 Cheque_Country=isnull(@Cheque_Country,Cheque_Country),  
 MailOption = isnull(@EmailFormat,MailOption)   
where AffId = @AffId  
  
IF @@Error <> 0  
BEGIN   
 SELECT @ErrMsg = CASE @Language   
      WHEN 'es-ES' THEN 'Error occurs. Update process is unsuccessful!'  
       WHEN 'zh-TW' THEN N'出現錯誤，更新程序失敗。'  
       WHEN 'zh-CN' THEN N'出现错误，更新程序失败。'  
       WHEN 'J' THEN N'Error occurs. Update process is unsuccessful!'  
       WHEN 'th-TH' THEN N'มีความผิดพลาดเกิดขึ้น อัพเดทข้อมูลไม่สำเร็จคะ!'  
       WHEN 'es-ES' THEN N'Se ha producido un error. No se ha podido completar el proceso de actualización.'  
       WHEN 'vi-VN' THEN N'Xảy ra lỗi. Quá trình cập nhật không thành công!'  
       WHEN 'id-ID' THEN N'Terjadi kesalahan. Proses pembaruan tidak berhasil!'  
	   when 'ko-KR' then N'에러 발생. 업데이트에 실패했습니다.'
       ELSE N'Error occurs. Update process is unsuccessful!'  
     END, @ErrCode = 1006  
 Rollback Transaction  
 RETURN  
END  
Commit Transaction  
  
--Update succeeded  
  
declare @SPName varchar(50), @Detail nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @Detail = 'Update Affifilate''s Info   
firstname='+ dbo.Aff_ToString(@firstname) + ',  
lastname='+ dbo.Aff_ToString(@lastname) + ',  
Gender='+ dbo.Aff_ToString(@Gender) + ',  
country='+ dbo.Aff_ToString(@country) + ',  
email='+ dbo.Aff_ToString(@email) + ',  
password='+ dbo.Aff_ToString(@password) + ',  
phone='+ dbo.Aff_ToString(@phone) + ',  
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',  
address='+ dbo.Aff_ToString(@address) + ',  
city='+ dbo.Aff_ToString(@city) + ',  
state='+ dbo.Aff_ToString(@state) + ',  
postal='+ dbo.Aff_ToString(@postal) + ',  
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
NoSiteDesc='+ dbo.Aff_ToString(@NoSiteDesc) + ',  
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
IsPageEnabled='+ dbo.Aff_ToString(@IsPageEnabled) + ',  
Level='+ dbo.Aff_ToString(@Level) + ',  
  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@Detail

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO bodbAdminNet
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdInfo] TO [VNTeam] 
