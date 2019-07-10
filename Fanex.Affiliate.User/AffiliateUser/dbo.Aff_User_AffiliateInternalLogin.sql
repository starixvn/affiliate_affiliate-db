/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffiliateInternalLogin]
	@AdminID		int,
	@UserName		varchar(50),	
	@LoginIP		varchar(20),
	@ServerID		int,	
	@Language		varchar(20) = 'en-US',
	@InputAffType	int = 1,--Check Kiosk system login
	@ErrCode		int = 0 OUTPUT,
	@ErrMsg			nvarchar(4000) = '' OUTPUT
AS

/*
	Created: 20090316@Ken
	Task: Login Affiliate from Admin site (internal login)
	DB: DBAFF.Affiliate_Athena000
	
	Revisions:
		- 201140321@Dan: return currencyID for web
		- 20151207@Francis: Revise sp to get Admin Username from bodb_Licensee for SSO
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_AdminUserInfo_Select
*/

SET NOCOUNT ON
declare @LogData nvarchar(200)

Declare @failedcount int
Declare @closed bit, @status varchar(30)
Declare @AdminUserName varchar(50)
Declare @AffID int
Declare @FirstName nvarchar(50)
Declare @LastName nvarchar(50)
Declare @Email nvarchar(50)
Declare @IsAllowedPersonalizedPage bit
Declare @Currency varchar(6)
Declare @CurrencyID int
Declare @AffType int
Declare @PreferLang varchar(11)
Declare @Prefix varchar(3)
Declare @AffLevel int

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

SELECT @AdminUserName = ''

DECLARE @sql NVARCHAR(MAX)
DECLARE @tblUsers TABLE (Username NVARCHAR(50))

SELECT  @sql = 'SELECT Username FROM OPENQUERY(DBCUST,
							''SELECT Username FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @AdminID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

INSERT INTO @tblUsers (Username)
EXEC (@sql)

SELECT @AdminUserName = Username FROM @tblUsers

/*
SELECT @AdminUserName = UserName
FROM AdminUser WITH(NOLOCK)
WHERE CustID = @AdminID
*/

SELECT @AffID = i.affID,
	@failedcount = LoginCount,
	@FirstName = firstname,
	@LastName = lastname,
	@Email = Email,
	@closed = IsClosed,
	@Status = Status,
	@PreferLang = d.PreferredLanguage,
	@IsAllowedPersonalizedPage=i.IsPageEnabled,
	@AffLevel=i.Level,
	@Prefix = isnull(Prefix, '$'),
	@AffType = AffType,
	@Currency = c.CurrencyCode,
	@CurrencyID = c.CurrencyID
FROM AffInfo i with (nolock)
	INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID
	left join Exchange e with(nolock) on e.ExchangeID = i.Currency
	inner join Currency c with(nolock) on i.Currency = c.CurrencyID
WHERE i.username = @UserName

-- user not found
IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
BEGIN
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'
	EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

	select @ErrMsg = case @Language	when 'en-US' then 'Wrong username or password.'
									when 'zh-TW' then N'????????'
									when 'zh-CN' then N'????????'
									when 'J' then N'Wrong username or password.'
									when 'th-TH' then N'Wrong username or password.'
									when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'
									when 'vi-VN' then N'Tên truy c?p ho?c m?t kh?u sai.'
									when 'id-ID' then N'Nama pengguna dan kata sandi salah.'
									else N'Wrong username or password.'
								end	,@ErrCode=1006
END

IF IsNull(@closed, 1) = 1
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)
		EXEC [dbo].[Aff_WriteLog] 
			@Creator = @AdminID, 
			@AffID = @AffID, 
			@Typename = 'LoginAdmin', 
			@SPName = @SPName, 
			@IP = @LoginIP, 
			@Details = @LogData

		select @ErrMsg =	case @Language	when 'en-US' then 'Your account is closed. Please contact your administrator!'
								when 'zh-TW' then N'????. ??????.'
								when 'zh-CN' then N'????,??????'
								when 'J' then N'Your account is closed. Please contact your administrator!'
								when 'th-TH' then N'Your account is closed. Please contact your administrator!'
								when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài kho?n c?a b?n b? dóng. Vui lòng liên h? v?i qu?n tr? viên c?a b?n!'
								when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
								else N'Your account is closed. Please contact your administrator!'
							end	,@ErrCode=1008
	END

--check pending or expired
IF @status <> 'Approved'	
BEGIN  
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)
	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @AdminID, 
		@AffID = @AffID, 
		@Typename = 'LoginAdmin', 
		@SPName = @SPName, 
		@IP = @LoginIP, 
		@Details = @LogData
	
	select @ErrMsg =	case @Language	when 'en-US' then 'Account is not approved. Please contact your administrator!'
								when 'zh-TW' then N'?????,???????'
								when 'zh-CN' then N'?????,??????'
								when 'J' then N'Account is not approved. Please contact your administrator!'
								when 'th-TH' then N'Account is not approved. Please contact your administrator!'
								when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài kho?n không du?c ch?p nh?n. Vui lòng liên h? v?i qu?n tr? viên c?a b?n!'
								when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
								else N'Account is not approved. Please contact your administrator!'
						end	,@ErrCode=1009
END 

SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)
EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @AffID = @AffID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

SELECT @AdminUserName [AdminUserName],
	@FirstName FirstName,
	@LastName LastName, 
	@Email Email, 
	@AffID AffID, 
	@PreferLang PreferLang, 
	@Prefix Prefix, 
	@IsAllowedPersonalizedPage IsAllowedPersonalizedPage, 
	@AffLevel AffLevel, 
	@AffType AffType, 
	@Currency Currency,
	@CurrencyID CurrencyID
GO