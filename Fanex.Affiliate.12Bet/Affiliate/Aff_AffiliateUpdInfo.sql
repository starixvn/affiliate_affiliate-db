/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateUpdInfo]
	@AffId int ,  
	@userid int,  
	@firstname nvarchar(50) = NULL,  
	@lastname nvarchar(50) = NULL,  
	@Gender bit = null,  
	@country nvarchar(50) = NULL,  
	@email nvarchar(50)=NULL,  
	@password varchar(40)=NULL,  
	@phone varchar(50)=NULL,  
	@ContactApps nvarchar(2000)=NULL,  
	@address nvarchar(250)=NULL,  
	@city nvarchar(250)=NULL,   
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
	@NoSiteDesc nvarchar(1000) = NULL,  
	@PreferredLanguage varchar(11)=NULL,  
	@PreferredPayment varchar(20)='Player', --Player, Neteller, Moneybookers, Wire, Cheque  
	@Player_Username varchar(100)=NULL,  
	@Neteller_AccountID varchar(50)=NULL,  
	@Moneybookers_Email nvarchar(50)=NULL,  
	@Wire_BankName  nvarchar(100)=NULL,  
	@Wire_BankAddress nvarchar(200)=NULL,  
	@Wire_SwiftCode  nvarchar(50)=NULL,  
	@Wire_AccountName nvarchar(100)=NULL,   
	@Wire_AccountNo  varchar(100)=NULL,  
	@Cheque_FullName nvarchar(200)=NULL,  
	@Cheque_Address  nvarchar(200)=NULL,  
	@Cheque_City  nvarchar(50)=NULL,  
	@Cheque_State  nvarchar(50)=NULL,  
	@Cheque_Postal  nvarchar(50)=NULL,  
	@Cheque_Country  varchar(50)=NULL,  
	---------------------------------------------------------------------------------  
	@language varchar(20) = 'en-US',  
	@IP varchar(20),  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(200) = '' OUTPUT  
AS  

/*
	Created: 20090324@VinhTrinh  
	Task: Update affiliate infor.  
	DB: DBAFF.Affiliate_12BET  
	Original : [Aff_AffiliateUpdInfo]  
	
	Revisions:  
		- 20100209@Peter: Check If Admin update Player_UserName, we must make sure there is no pending payment request.
		- 20180503@Walter: Fix data type [RedmineID: #94522]
		- 20180601@Percy: Add ContactApps [RedmineID: #87923]
   
	Param's Explanation:  
		• @AffId : Affiliate custid  
		• @userid : user update.  
		• @firstname : update firstname.  
*/ 

BEGIN
	SET NOCOUNT ON  
	-- Check permission
	IF @AffId <> @UserId
	BEGIN
		EXEC [dbo].[Aff_Con_CheckPermission]   
			@custid=@UserID,
			@funcname='[Affiliate]',
			@System = 'AFFILIATE',
			@ErrCode=@ErrCode output,
			@ErrMsg=@ErrMsg output

		IF @ErrCode <> 0
			RETURN
	END

	SELECT @ErrCode = 0
  
	-- Check If we change player_username  
	IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffId = @AffId AND @Player_Username <> Player_UserName)
		AND EXISTS (SELECT 1 FROM dbo.AffPayOut WITH (NOLOCK) WHERE AffId = @AffId AND Status = 'pending')
	BEGIN
		-- Oops, this account is having 1 pending pay out request, please update this transaction first!
		SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)

		RETURN
	END
  
	-- Check duplicate Email   
	IF EXISTS (Select 1 From AffInfo a with (nolock) where a.email=@email and a.AffId <> @AffId and a.Status <> 'Disapproved')
	BEGIN
		-- Email Address has been used. Please choose another one!
		SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(302, @Language)

		RETURN
	END

	DECLARE @UpdatedData TABLE
	(
		-- del
		PreferredLanguage_Del	VARCHAR(20),
		Password_Del			VARCHAR(40),
		AffType_Del				TINYINT,
		Status_Del				VARCHAR(30),
		ApprovedDate_Del		SMALLDATETIME,
		CasinoJoinedDate_Del	SMALLDATETIME,
		Closed_Del				BIT,
		FirstName_Del			NVARCHAR(50),
		LastName_Del			NVARCHAR(50),
		Email_Del				NVARCHAR(50),
		IsPageEnabled_Del		BIT,
		Level_Del				TINYINT,
		Gender_Del				BIT,
		Country_Del				NVARCHAR(50),
		Phone_Del				VARCHAR(50),
		ContactApps_Del			NVARCHAR(2000),
		Address_Del				NVARCHAR(250),
		City_Del				NVARCHAR(250),
		State_Del				NVARCHAR(50),
		Postal_Del				NVARCHAR(50),
		SiteURL_Del				VARCHAR(100),
		MoreSiteURLs_Del		VARCHAR(1000),
		NoSiteDesc_Del			NVARCHAR(1000),
		PreferredPayment_Del	VARCHAR(20),
		Player_IBCCustId_Del	INT,
		Player_Username_Del		NVARCHAR(50),
		Neteller_AccountId_Del	VARCHAR(50),
		Moneybookers_Email_Del	NVARCHAR(50),
		Wire_BankName_Del		NVARCHAR(100),
		Wire_BankAddress_Del	NVARCHAR(200),
		Wire_SwiftCode_Del		NVARCHAR(50),
		Wire_AccountName_Del	NVARCHAR(100),
		Wire_AccountNo_Del		VARCHAR(100),
		MailOption_Del			BIT,
		-- insert
		PreferredLanguage_Ins	VARCHAR(20),
		Password_Ins			VARCHAR(40),
		AffType_Ins				TINYINT,
		Status_Ins				VARCHAR(30),
		ApprovedDate_Ins		SMALLDATETIME,
		CasinoJoinedDate_Ins	SMALLDATETIME,
		Closed_Ins				BIT,
		FirstName_Ins			NVARCHAR(50),
		LastName_Ins			NVARCHAR(50),
		Email_Ins				NVARCHAR(50),
		IsPageEnabled_Ins		BIT,
		Level_Ins				TINYINT,
		Gender_Ins				BIT,
		Country_Ins				NVARCHAR(50),
		Phone_Ins				VARCHAR(50),
		ContactApps_Ins			NVARCHAR(2000),
		Address_Ins				NVARCHAR(250),
		City_Ins				NVARCHAR(250),
		State_Ins				NVARCHAR(50),
		Postal_Ins				NVARCHAR(50),
		SiteURL_Ins				VARCHAR(100),
		MoreSiteURLs_Ins		VARCHAR(1000),
		NoSiteDesc_Ins			NVARCHAR(1000),
		PreferredPayment_Ins	VARCHAR(20),
		Player_IBCCustId_Ins	INT,
		Player_Username_Ins		NVARCHAR(50),
		Neteller_AccountId_Ins	VARCHAR(50),
		Moneybookers_Email_Ins	NVARCHAR(50),
		Wire_BankName_Ins		NVARCHAR(100),
		Wire_BankAddress_Ins	NVARCHAR(200),
		Wire_SwiftCode_Ins		NVARCHAR(50),
		Wire_AccountName_Ins	NVARCHAR(100),
		Wire_AccountNo_Ins		VARCHAR(100),
		MailOption_Ins			BIT
	)

	-- Update process
	BEGIN TRY
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET FirstName = ISNULL(@FirstName, FirstName),
			LastName = ISNULL(@LastName, LastName),
			Email = ISNULL(@Email, Email),
			Password = ISNULL(@Password, Password),
			IsPageEnabled = ISNULL(@IsPageEnabled, IsPageEnabled),
			Level = ISNULL(@Level, Level)
		OUTPUT	DELETED.FirstName, DELETED.LastName, DELETED.Email, DELETED.Password, DELETED.IsPageEnabled, DELETED.Level,
				INSERTED.FirstName, INSERTED.LastName, INSERTED.Email, INSERTED.Password, INSERTED.IsPageEnabled, INSERTED.Level
		INTO @UpdatedData (FirstName_Del, LastName_Del, Email_Del, Password_Del, IsPageEnabled_Del, Level_Del,
							FirstName_Ins, LastName_Ins, Email_Ins, Password_Ins, IsPageEnabled_Ins, Level_Ins)
		WHERE AffId = @AffId
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1004, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

		RETURN
	END CATCH

	DECLARE @Player_IBCCustId INT
	SELECT  @Player_IBCCustId = custid
	FROM DBEXT.bodb02.dbo.Customer WITH (NOLOCK)
	WHERE username2 = '12BET$' + @Player_Username

	BEGIN TRY
		UPDATE AffDetail  with(rowlock,updlock)   
		SET Gender = isnull(@Gender,Gender),
			country = isnull(@country,country),
			phone = isnull(@phone,phone),
			ContactApps = isnull(@ContactApps,ContactApps),
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
		OUTPUT	DELETED.Gender,DELETED.Country,DELETED.Phone,DELETED.ContactApps,
				DELETED.Address,DELETED.City,DELETED.State,DELETED.Postal,
				DELETED.SiteURL,DELETED.MoreSiteURLs,DELETED.NoSiteDesc,DELETED.PreferredLanguage,DELETED.PreferredPayment,
				DELETED.Player_IBCCustId,DELETED.Player_Username,DELETED.Neteller_AccountId,DELETED.Moneybookers_Email,
				DELETED.Wire_BankName,DELETED.Wire_BankAddress,DELETED.Wire_SwiftCode,DELETED.Wire_AccountName,
				DELETED.Wire_AccountNo,DELETED.MailOption,
				INSERTED.Gender,INSERTED.Country,INSERTED.Phone,INSERTED.ContactApps,
				INSERTED.Address,INSERTED.City,INSERTED.State,INSERTED.Postal,
				INSERTED.SiteURL,INSERTED.MoreSiteURLs,INSERTED.NoSiteDesc,INSERTED.PreferredLanguage,INSERTED.PreferredPayment,
				INSERTED.Player_IBCCustId,INSERTED.Player_Username,INSERTED.Neteller_AccountId,INSERTED.Moneybookers_Email,
				INSERTED.Wire_BankName,INSERTED.Wire_BankAddress,INSERTED.Wire_SwiftCode,INSERTED.Wire_AccountName,
				INSERTED.Wire_AccountNo,INSERTED.MailOption
		INTO @UpdatedData
		(
				Gender_Del,Country_Del,Phone_Del,ContactApps_Del,
				Address_Del,City_Del,State_Del,Postal_Del,
				SiteURL_Del,MoreSiteURLs_Del,NoSiteDesc_Del,PreferredLanguage_Del,PreferredPayment_Del,
				Player_IBCCustId_Del,Player_Username_Del,Neteller_AccountId_Del,Moneybookers_Email_Del,
				Wire_BankName_Del,Wire_BankAddress_Del,Wire_SwiftCode_Del,Wire_AccountName_Del,
				Wire_AccountNo_Del,MailOption_Del,
				Gender_Ins,Country_Ins,Phone_Ins,ContactApps_Ins,
				Address_Ins,City_Ins,State_Ins,Postal_Ins,
				SiteURL_Ins,MoreSiteURLs_Ins,NoSiteDesc_Ins,PreferredLanguage_Ins,PreferredPayment_Ins,
				Player_IBCCustId_Ins,Player_Username_Ins,Neteller_AccountId_Ins,Moneybookers_Email_Ins,
				Wire_BankName_Ins,Wire_BankAddress_Ins,Wire_SwiftCode_Ins,Wire_AccountName_Ins,
				Wire_AccountNo_Ins,MailOption_Ins
		)
		WHERE AffId = @AffId  
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE ai WITH (ROWLOCK, UPDLOCK)
		SET FirstName = ud.FirstName_Del,
			LastName = ud.LastName_Del,
			Email = ud.Email_Del,
			IsPageEnabled = ud.IsPageEnabled_Del,
			Level = ud.Level_Del
		FROM dbo.AffInfo ai
			CROSS APPLY @UpdatedData ud
		WHERE AffId = @AffId

		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT	@OldData =
				'FirstName='			+ ISNULL(FirstName_Del, '') + ',' +
				'LastName='				+ ISNULL(LastName_Del, '') + ',' +
				'Email='				+ ISNULL(Email_Del, '') + ',' +
				'IsPageEnabled='		+ ISNULL(CONVERT(VARCHAR(1), IsPageEnabled_Del), '') + ',' +
				'Level='				+ ISNULL(CONVERT(VARCHAR(10), Level_Del), '') + ',' +
				'Gender='				+ ISNULL(CONVERT(VARCHAR(1), Gender_Del), '') + ',' +
				'Country='				+ ISNULL(Country_Del, '') + ',' +
				'Phone='				+ ISNULL(Phone_Del, '') + ',' +
				'ContactApps='			+ ISNULL(ContactApps_Del, '') + ',' +
				'Address='				+ ISNULL(Address_Del, '') + ',' +
				'City='					+ ISNULL(City_Del, '') + ',' +
				'State='				+ ISNULL(State_Del, '') + ',' +
				'Postal='				+ ISNULL(Postal_Del, '') + ',' +
				'SiteURL='				+ ISNULL(SiteURL_Del, '') + ',' +
				'MoreSiteURLs='			+ ISNULL(MoreSiteURLs_Del, '') + ',' +
				'NoSiteDesc='			+ ISNULL(NoSiteDesc_Del, '') + ',' +
				'PreferredLanguage='	+ ISNULL(PreferredLanguage_Del, '') + ',' +
				'PreferredPayment='		+ ISNULL(PreferredPayment_Del, '') + ',' +
				'Player_IBCCustId='		+ ISNULL(CONVERT(VARCHAR(15), Player_IBCCustId_Del), '') + ',' +
				'Player_Username='		+ ISNULL(Player_Username_Del, '') + ',' +
				'Neteller_AccountId='	+ ISNULL(Neteller_AccountId_Del, '') + ',' +
				'Moneybookers_Email='	+ ISNULL(Moneybookers_Email_Del, '') + ',' +
				'Wire_BankName='		+ ISNULL(Wire_BankName_Del, '') + ',' +
				'Wire_BankAddress='		+ ISNULL(Wire_BankAddress_Del, '') + ',' +
				'Wire_SwiftCode='		+ ISNULL(Wire_SwiftCode_Del, '') + ',' +
				'Wire_AccountName='		+ ISNULL(Wire_AccountName_Del, '') + ',' +
				'Wire_AccountNo='		+ ISNULL(Wire_AccountNo_Del, '') + ',' +
				'MailOption='			+ ISNULL(CONVERT(VARCHAR(1), MailOption_Del), ''),
			@NewData =
				'FirstName='			+ ISNULL(FirstName_Ins, '') + ',' +
				'LastName='				+ ISNULL(LastName_Ins, '') + ',' +
				'Email='				+ ISNULL(Email_Ins, '') + ',' +
				'IsPageEnabled='		+ ISNULL(CONVERT(VARCHAR(1), IsPageEnabled_Ins), '') + ',' +
				'Level='				+ ISNULL(CONVERT(VARCHAR(10), Level_Ins), '') + ',' +
				'Gender='				+ ISNULL(CONVERT(VARCHAR(1), Gender_Ins), '') + ',' +
				'Country='				+ ISNULL(Country_Ins, '') + ',' +
				'Phone='				+ ISNULL(Phone_Ins, '') + ',' +
				'ContactApps='			+ ISNULL(ContactApps_Ins, '') + ',' +
				'Address='				+ ISNULL(Address_Ins, '') + ',' +
				'City='					+ ISNULL(City_Ins, '') + ',' +
				'State='				+ ISNULL(State_Ins, '') + ',' +
				'Postal='				+ ISNULL(Postal_Ins, '') + ',' +
				'SiteURL='				+ ISNULL(SiteURL_Ins, '') + ',' +
				'MoreSiteURLs='			+ ISNULL(MoreSiteURLs_Ins, '') + ',' +
				'NoSiteDesc='			+ ISNULL(NoSiteDesc_Ins, '') + ',' +
				'PreferredLanguage='	+ ISNULL(PreferredLanguage_Ins, '') + ',' +
				'PreferredPayment='		+ ISNULL(PreferredPayment_Ins, '') + ',' +
				'Player_IBCCustId='		+ ISNULL(CONVERT(VARCHAR(15), Player_IBCCustId_Ins), '') + ',' +
				'Player_Username='		+ ISNULL(Player_Username_Ins, '') + ',' +
				'Neteller_AccountId='	+ ISNULL(Neteller_AccountId_Ins, '') + ',' +
				'Moneybookers_Email='	+ ISNULL(Moneybookers_Email_Ins, '') + ',' +
				'Wire_BankName='		+ ISNULL(Wire_BankName_Ins, '') + ',' +
				'Wire_BankAddress='		+ ISNULL(Wire_BankAddress_Ins, '') + ',' +
				'Wire_SwiftCode='		+ ISNULL(Wire_SwiftCode_Ins, '') + ',' +
				'Wire_AccountName='		+ ISNULL(Wire_AccountName_Ins, '') + ',' +
				'Wire_AccountNo='		+ ISNULL(Wire_AccountNo_Ins, '') + ',' +
				'MailOption='			+ ISNULL(CONVERT(VARCHAR(1), MailOption_Ins), '')
	FROM @UpdatedData

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= @AffId,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO