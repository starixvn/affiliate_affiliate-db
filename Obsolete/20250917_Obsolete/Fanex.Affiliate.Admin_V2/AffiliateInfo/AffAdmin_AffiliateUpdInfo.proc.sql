/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdInfo] 
	@AffId INT
	,@userid INT
	,@firstname NVARCHAR(50) = NULL
	,@lastname NVARCHAR(50) = NULL
	,@Gender BIT = NULL
	,@country NVARCHAR(50) = NULL
	,@email NVARCHAR(50) = NULL
	,@password VARCHAR(40) = NULL
	,@phone NVARCHAR(50) = NULL
	,@mobilephone NVARCHAR(50) = NULL
	,@address NVARCHAR(80)
	,@city NVARCHAR(50) = NULL
	,@state NVARCHAR(50) = NULL
	,@postal NVARCHAR(50) = NULL
	,@emailformat BIT = NULL
	,@currency SMALLINT = NULL
	,@playerCurrency NVARCHAR(50) = NULL
	,
	--Add for Personalized Site  
	@IsPageEnabled BIT = 0
	,@Level INT = 0
	,
	---------------------------------------------------------------------------------  
	-- Parameter for Affiliate info(use for update/insert data to DB03)  
	@SiteURL VARCHAR(100) = NULL
	,@MoreSiteURLs VARCHAR(1000) = NULL
	,@PreferredLanguage VARCHAR(11) = NULL
	,@PreferredPayment VARCHAR(20)
	,--Player, Neteller, Moneybookers, Wire, Cheque  
	@Player_Username VARCHAR(30) = NULL
	,@Neteller_AccountID VARCHAR(50) = NULL
	,@Moneybookers_Email VARCHAR(50) = NULL
	,@Wire_BankName NVARCHAR(100) = NULL
	,@Wire_BankAddress NVARCHAR(200) = NULL
	,@Wire_SwiftCode NVARCHAR(20) = NULL
	,@Wire_AccountName NVARCHAR(100) = NULL
	,@Wire_AccountNo VARCHAR(50) = NULL
	,@Cheque_FullName NVARCHAR(200) = NULL
	,@Cheque_Address NVARCHAR(200) = NULL
	,@Cheque_City NVARCHAR(50) = NULL
	,@Cheque_State NVARCHAR(50) = NULL
	,@Cheque_Postal NVARCHAR(50) = NULL
	,@Cheque_Country VARCHAR(50) = NULL
	,
	---------------------------------------------------------------------------------  
	@language VARCHAR(20) = 'es-ES'
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
AS

/*
	Created by: 20090324@VinhTrinh  
	Task: Update affiliate infor.  
	DB: DBAFF
	Original : [Aff_AffiliateUpdInfo]  
	
	Revisions:  
		- 20100209@Peter: Check If Admin update Player_UserName, we must make sure there is no pending payment request.  
		- 20110228@Johnny: Do not allow affiliate update player_user if they have already  
		- 20130319@Johnny: Do not allow update currency  
		- 20130911@Long: do not check email existance in case of Kiosk
		- 20140514@Bobby: check/remove unique email (remove check afftype [Kiosk, ...])
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20180205@Percy: Remove redundant param: @LicenseeId [RedmineID: #90545]

	Param's Explanation:  
		• @AffId: Affiliate custid  
		• @userid: user update.  
		• @firstname: update firstname.  
*/

BEGIN
	SET NOCOUNT ON
	
	--Check If we change player_username  
	IF (
			@Player_Username IS NOT NULL
			AND @Player_Username <> (
				SELECT Player_UserName
				FROM AffDetail WITH (NOLOCK)
				WHERE AffId = @AffID
				)
			AND EXISTS (
				SELECT 1
				FROM AffPayout WITH (NOLOCK)
				WHERE AffID = @AffID
					AND STATUS = 'pending'
				)
			)
	BEGIN
		SELECT @ErrCode = 1004

		RETURN
	END

	-----------------------------------------------  
	--Check duplicate Email 
	IF EXISTS (
			SELECT TOP 1 1
			FROM AffInfo a WITH (NOLOCK)
			WHERE a.email = @email
				AND a.AffId <> @AffId
				AND a.STATUS <> 'Disapproved'
			)
	BEGIN
		SELECT @ErrCode = 15

		RETURN
	END

	BEGIN TRANSACTION

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET firstname = isnull(@firstname, firstname)
		,lastname = isnull(@lastname, lastname)
		,email = isnull(@email, email)
		,Password = isnull(@password, Password)
		,IsPageEnabled = isnull(@IsPageEnabled, IsPageEnabled)
		,[Level] = isnull(@Level, [Level])
		,Currency = (CASE 
			WHEN STATUS IN ('Pending', 'Disapproved') THEN isnull(@currency, currency)
			ELSE currency END
			)
	WHERE AffId = @AffId

	IF @@error <> 0
	BEGIN
		SELECT @ErrCode = 16

		ROLLBACK TRANSACTION

		RETURN
	END

	UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
	SET Gender = isnull(@Gender, Gender)
		,CountryID = isnull(@country, countryID)
		,phone = isnull(@phone, phone)
		,mobilephone = isnull(@mobilephone, mobilephone)
		,address = isnull(@address, address)
		,city = isnull(@city, city)
		,STATE = isnull(@state, STATE)
		,postal = isnull(@postal, postal)
		,SiteURL = isnull(@SiteURL, SiteURL)
		,MoreSiteURLs = @MoreSiteURLs
		,PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage)
		,PreferredPayment = @PreferredPayment
		,
		--Player_IBCCustID=@Player_IBCCustId,   
		Player_Username = CASE 
			WHEN @AffId <> @UserId THEN @Player_Username
			ELSE isnull(Player_Username, @Player_Username)
			END
		,Player_Currency = @playerCurrency
		,Neteller_AccountID = @Neteller_AccountID
		,Moneybookers_Email = @Moneybookers_Email
		,Wire_BankName = @Wire_BankName
		,Wire_BankAddress = @Wire_BankAddress
		,Wire_SwiftCode = @Wire_SwiftCode
		,Wire_AccountName = @Wire_AccountName
		,Wire_AccountNo = @Wire_AccountNo
		,Cheque_FullName = @Cheque_FullName
		,Cheque_Address = @Cheque_Address
		,Cheque_City = @Cheque_City
		,Cheque_State = @Cheque_State
		,Cheque_Postal = @Cheque_Postal
		,Cheque_Country = @Cheque_Country
		,MailOption = @EmailFormat
	WHERE AffId = @AffId

	IF @@Error <> 0
	BEGIN
		SELECT @ErrCode = 17

		ROLLBACK TRANSACTION

		RETURN
	END

	COMMIT TRANSACTION

	--Update succeeded  
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Update Affifilate''s Info   
		firstname=' + dbo.Aff_ToString(@firstname) + ',  
		lastname=' + dbo.Aff_ToString(@lastname) + ',  
		Gender=' + dbo.Aff_ToString(@Gender) + ',  
		country=' + dbo.Aff_ToString(@country) + ',  
		email=' + dbo.Aff_ToString(@email) + ',  
		password=' + dbo.Aff_ToString(@password) + ',  
		phone=' + dbo.Aff_ToString(@phone) + ',  
		mobilephone=' + dbo.Aff_ToString(@mobilephone) + ',  
		address=' + dbo.Aff_ToString(@address) + ',  
		city=' + dbo.Aff_ToString(@city) + ',  
		state=' + dbo.Aff_ToString(@state) + ',  
		postal=' + dbo.Aff_ToString(@postal) + ',  
		SiteURL=' + dbo.Aff_ToString(@SiteURL) + ',  
		MoreSiteURLs=' + dbo.Aff_ToString(@MoreSiteURLs) + ',  
		PreferredPayment=' + dbo.Aff_ToString(@PreferredPayment) + ',  
		PreferredLanguage=' + dbo.Aff_ToString(@PreferredLanguage) + ',  
		Player_Username=' + dbo.Aff_ToString(@Player_Username) + ',  
		Player_Currency=' + @playerCurrency + ',  
		Neteller_AccountID=' + dbo.Aff_ToString(@Neteller_AccountID) + ',  
		Moneybookers_Email=' + dbo.Aff_ToString(@Moneybookers_Email) + ',  
		Wire_BankName=' + dbo.Aff_ToString(@Wire_BankName) + ',  
		Wire_BankAddress=' + dbo.Aff_ToString(@Wire_BankAddress) + ',  
		Wire_SwiftCode=' + dbo.Aff_ToString(@Wire_SwiftCode) + ',  
		Wire_AccountName=' + dbo.Aff_ToString(@Wire_AccountName) + ',  
		Wire_AccountNo=' + dbo.Aff_ToString(@Wire_AccountNo) + ',  
		Cheque_FullName=' + dbo.Aff_ToString(@Cheque_FullName) + ',  
		Cheque_Address=' + dbo.Aff_ToString(@Cheque_Address) + ',  
		Cheque_City=' + dbo.Aff_ToString(@Cheque_City) + ',  
		Cheque_State=' + dbo.Aff_ToString(@Cheque_State) + ',  
		Cheque_Postal=' + dbo.Aff_ToString(@Cheque_Postal) + ',  
		Cheque_Country=' + dbo.Aff_ToString(@Cheque_Country) + ',  
		IsPageEnabled=' + dbo.Aff_ToString(@IsPageEnabled) + ',  
		Level=' + dbo.Aff_ToString(@Level) + ',  
		Currency' + dbo.Aff_ToString(@Currency) + ',  
		language=' + dbo.Aff_ToString(@language)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'UserInfo'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @Detail
END
GO