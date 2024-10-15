/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffiliateInternalLogin]
	@AdminID		INT,
	@UserName		VARCHAR(50),	
	@LoginIP		VARCHAR(20),
	@ServerID		INT,	
	@InputAffType	INT = 1,--Check Kiosk system login
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
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
		- 20240722@Sally: Remove linked server to DBCUST [RedmineID: #206891]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @LogData NVARCHAR(200)

	DECLARE @failedcount			INT
		,@closed					BIT
		,@status					VARCHAR(30)
		,@AdminUserName				VARCHAR(50)
		,@AffID						INT
		,@FirstName					NVARCHAR(50)
		,@LastName					NVARCHAR(50)
		,@Email						NVARCHAR(50)
		,@IsAllowedPersonalizedPage BIT
		,@Currency					VARCHAR(6)
		,@CurrencyID				INT
		,@AffType					INT
		,@PreferLang				VARCHAR(11)
		,@Prefix					VARCHAR(3)
		,@AffLevel					INT

	DECLARE @SPName VARCHAR(50)
	SELECT @SPName = OBJECT_NAME(@@ProcID) 

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue 
	FROM dbo.SystemSettings WITH (NOLOCK) 
	WHERE SName = 'LicenseeID'

	SELECT @AdminUserName = ''

	DECLARE @sql NVARCHAR(MAX)
	DECLARE @tblUsers TABLE (Username NVARCHAR(50))

	SELECT @AdminUserName = Username 
	FROM  bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select (@AdminID, @LicenseeID)

	SELECT @AffID = i.affID,
		@failedcount = LoginCount,
		@FirstName = firstname,
		@LastName = lastname,
		@Email = Email,
		@closed = IsClosed,
		@Status = Status,
		@PreferLang = d.PreferredLanguage,
		@IsAllowedPersonalizedPage = i.IsPageEnabled,
		@AffLevel = i.Level,
		@Prefix = ISNULL(Prefix, '$'),
		@AffType = AffType,
		@Currency = c.CurrencyCode,
		@CurrencyID = c.CurrencyID
	FROM dbo.AffInfo i WITH (NOLOCK)
		INNER JOIN dbo.AffDetail d WITH (NOLOCK) ON i.AffID = d.affID
		LEFT JOIN dbo.Exchange   e WITH (NOLOCK) ON e.ExchangeID = i.Currency
		INNER JOIN dbo.Currency  c WITH (NOLOCK) ON i.Currency = c.CurrencyID
	WHERE i.UserName = @UserName

	-- user not found
	IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'
		EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

		SELECT @ErrMsg = N'Wrong username or password.',@ErrCode = 101
	END

	IF ISNULL(@closed, 1) = 1
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)
		EXEC [dbo].[Aff_WriteLog] 
			@Creator	= @AdminID, 
			@AffID		= @AffID, 
			@Typename	= 'LoginAdmin', 
			@SPName		= @SPName, 
			@IP			= @LoginIP, 
			@Details	= @LogData

		SELECT @ErrMsg = N'Your account is closed. Please contact your administrator!', @ErrCode=102 -- Only support EN language
	END

	--check pending or expired
	IF @status <> 'Approved'	
	BEGIN  
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)
		EXEC [dbo].[Aff_WriteLog] 
			@Creator	= @AdminID, 
			@AffID		= @AffID, 
			@Typename	= 'LoginAdmin', 
			@SPName		= @SPName, 
			@IP			= @LoginIP, 
			@Details	= @LogData
	
		SELECT @ErrMsg = N'Account is not approved. Please contact your administrator!', @ErrCode=105 -- Only support EN language
	END 

	SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)
	EXEC [dbo].[Aff_WriteLog] 
		@Creator	= @AdminID, 
		@AffID		= @AffID, 
		@Typename	= 'LoginAdmin', 
		@SPName		= @SPName, 
		@IP			= @LoginIP, 
		@Details	= @LogData

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
END
GO
