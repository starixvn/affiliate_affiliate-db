/****** Object:  Stored Procedure dbo.Aff_MediaAffiliateIns_xpre    Script Date: 12/25/2010 7:01:52 AM ******/  
/****** Object:  Stored Procedure dbo.Aff_MediaAffiliateIns    Script Date: 12/16/2010 1:55:00 PM ******/  
/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 11/3/2009 5:46:27 PM ******/  
Alter PROCEDURE [dbo].[Aff_MediaAffiliateIns]  
 @UserId int,  
 @AffMaster varchar(50) = '12BetMedia',  
 @AffId int OUTPUT,  
 @Username varchar(50) OUTPUT,  
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
 --------------------------------------------------     
 @SiteURL varchar(100),     
 @MoreSiteURLs varchar(1000) = NULL,    
 @PreferredLanguage varchar(5) = 'en-US',       
 @IP varchar(20),    
 @Browser varchar(100)='',    
 --------------------------------------------------    
 @language varchar(2) = 'en-US',     
 @ErrCode int = 0 OUTPUT,    
 @ErrMsg nvarchar(200) = '' OUTPUT    
AS  
/*      
Created:     
Task : Register new Affiliate    
DB: DB052.Affiliate_12BET  
Original: [Aff_AffiliateIns]    
Revisions:      
  
Param's Explanation:      
• @ErrCode:      
    = 0: Create agent successfully.      
    > 0: Specific Error.      
        
• @ErrMsg: Error description.      
*/     
SET NOCOUNT ON  
  
EXEC [dbo].[Aff_Con_CheckPermission_xpre]   
  @custid=@UserID,  
  @funcname='[MediaAffiliate]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
  
Declare @AffType tinyint, @Status varchar(30), @IsClosed bit, @Currency int, @GroupId int, @GroupName nvarchar(100)  
  
select @GroupName = 'NoCommission'  
  
Select @GroupId = GroupId from CommGroup nolock where GroupName = @GroupName  
  
select @AffType = 2, @Status = 'Approved', @IsClosed = 0, @Currency = 3  
  
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
	  when 'ko-KR' then N'이미 사용된 이메일입니다. 다른 이메일을 사용해 주십시오.' 
      else N'Email Address has been used. Please choose another one!'    
      end, @ErrCode = 1002  
 return  
END     
  
--Generate username-----------------    
--Exec Aff_GenUsername @AffPrefix = @AffMaster, @username = @username OUTPUT     
  
if exists(select 1 from AffInfo with (nolock) where username = @username)    
BEGIN    
 Exec Aff_GenUsername @AffPrefix = @AffMaster, @username = @username OUTPUT--Generate new username  
END   
  
Insert into AffInfo(  
 [UserName]  
 ,[FirstName]  
 ,[LastName]  
 ,[Status]  
 ,[IsClosed]  
 ,[Currency]  
 ,[RegisteredDate]  
 ,[ApprovedDate]  
 ,[Email]  
 ,[Password]  
 ,[AffType]  
 ,[GroupId])  
Values  
(  
 @Username  
 ,@FirstName  
 ,@LastName  
 ,@Status  
 ,@IsClosed  
 ,@Currency  
 ,GetDate()  
 ,GetDate()  
 ,@Email  
 ,''  
 ,@AffType  
 ,@GroupId  
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
	when 'ko-KR' then N'고객 생성에 실패했습니다. 다시 시도해 주세요.'
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
 ,[Country]  
 ,[Phone]  
 ,[MobilePhone]  
 ,[Fax]  
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
	when 'ko-KR' then N'고객 생성에 실패했습니다. 다시 시도해 주세요.'
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
    
Select @LogData = 'Add new Media Affifilate  
affid'+ dbo.Aff_ToString(@AffId) + ',  
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
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData
	
GO
GRANT EXECUTE ON [dbo].[Aff_MediaAffiliateIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MediaAffiliateIns] TO [VNTeam]