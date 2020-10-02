/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateInfo_Upd]
	@UserId				INT,
	@AffId				INT,
	@FirstName			NVARCHAR(50) = NULL,
	@LastName			NVARCHAR(50) = NULL,
	@Gender				BIT = NULL,
	@Email				NVARCHAR(50) = NULL,
	@Phone				VARCHAR(50) = NULL,
	@ContactApps		NVARCHAR(2000) = NULL,
	@Address			NVARCHAR(250) = NULL,
	@City				NVARCHAR(250) = NULL,
	@State				NVARCHAR(50) = NULL,
	@Postal				NVARCHAR(50) = NULL,
	@Country			NVARCHAR(50) = NULL,
	@QuestionId			TINYINT = NULL,
	@Answer				NVARCHAR(300) = NULL,
	@MailOption			BIT = NULL,
	@SiteURL			VARCHAR(100) = NULL,
	@MoreSiteURLs		VARCHAR(1000) = NULL,
	@NoSiteDesc			NVARCHAR(1000) = NULL,
	-- Payment Information: Player, Neteller, Moneybookers, Bank Transfer
	@PreferredPayment	VARCHAR(20) = NULL,
		-- Player
	@PlayerUsername		NVARCHAR(50) = NULL,
		-- Neteller
	@NetellerAccountId	NVARCHAR(50) = NULL,
		-- Moneybookers
	@MoneybookersEmail	NVARCHAR(50) = NULL,
		-- Bank Transfer
	@BankName			NVARCHAR(100) = NULL,
	@BankAddress		NVARCHAR(200) = NULL,
	@BankSwiftCode		NVARCHAR(50) = NULL,
	@BankAccountName	NVARCHAR(100) = NULL,
	@BankAccountNo		NVARCHAR(100) = NULL,
	-- End Payment Information
	-- Update on left menu
	@PreferredLanguage	VARCHAR(20) = NULL,
	@Password			NVARCHAR(40) = NULL,
	@AffType			TINYINT	= NULL,
	@Status				VARCHAR(30) = NULL,
	@GroupId			INT = NULL, -- with status = approved
	@Closed				BIT = NULL,
	-- End left menu
	@IP					VARCHAR(50),
	@Language			VARCHAR(20) = 'en-US',
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS  

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin site - Customer - Edit - Update Info (Exclude Preferrence Language and Password)
		Admin site - Customer - Left menu - Update Preferrence Language / Password
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = GETDATE()

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[Affiliate]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
	BEGIN
		-- Invalid Affiliate!
		SELECT @ErrCode = 1003, @ErrMsg = dbo.Aff_f_GetMessageById(304, @Language)
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
		QuestionId_Del			TINYINT,
		Answer_Del				NVARCHAR(300),
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
		MailOption_Ins			BIT,
		QuestionId_Ins			TINYINT,
		Answer_Ins				NVARCHAR(300)
	)

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	-- Update Password and Status when approving affiliate
	IF @Password IS NOT NULL AND @Status IS NOT NULL
	BEGIN
		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET Password = ISNULL(@Password, Password),
				Status = ISNULL(@Status, Status)
			OUTPUT DELETED.Password, DELETED.Status, INSERTED.Password, INSERTED.Status
			INTO @UpdatedData (Password_Del, Status_Del, Password_Ins, Status_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData =
					'Password=' + ISNULL(Password_Del, '') + ',' +
					'Status='	+ ISNULL(Status_Del, ''),
				@NewData =
					'Password=' + ISNULL(Password_Ins, '') + ',' +
					'Status='	+ ISNULL(Status_Ins, '')
		FROM @UpdatedData
	END
	-- Update Preference Language only (Left menu)
	ELSE IF @PreferredLanguage IS NOT NULL
	BEGIN
		BEGIN TRY
			UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
			SET PreferredLanguage = ISNULL(@PreferredLanguage, PreferredLanguage)
			OUTPUT DELETED.PreferredLanguage, INSERTED.PreferredLanguage
			INTO @UpdatedData (PreferredLanguage_Del, PreferredLanguage_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData = 'PreferredLanguage=' + ISNULL(PreferredLanguage_Del, ''),
				@NewData = 'PreferredLanguage=' + ISNULL(PreferredLanguage_Ins, '')
		FROM @UpdatedData
	END
	-- Update Password only (Left menu)
	ELSE IF @Password IS NOT NULL
	BEGIN
		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET Password = ISNULL(@Password, Password)
			OUTPUT DELETED.Password, INSERTED.Password
			INTO @UpdatedData (Password_Del, Password_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData = 'Password=' + ISNULL(Password_Del, ''),
				@NewData = 'Password=' + ISNULL(Password_Ins, '')
		FROM @UpdatedData
	END
	-- Update AffType only (Left menu)
	ELSE IF @AffType IS NOT NULL
	BEGIN
		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET AffType = ISNULL(@AffType, AffType)
			OUTPUT DELETED.AffType, INSERTED.AffType
			INTO @UpdatedData (AffType_Del, AffType_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData = 'AffType=' + ISNULL(CONVERT(VARCHAR(20), AffType_Del), ''),
				@NewData = 'AffType=' + ISNULL(CONVERT(VARCHAR(20), AffType_Ins), '')
		FROM @UpdatedData
	END
	-- Update Status only (Left menu)
	ELSE IF @Status IS NOT NULL
	BEGIN
		IF @Status NOT IN ('Pending', 'Approved', 'Disapproved')
		BEGIN
			-- Invalid status
			SELECT @ErrCode = 1004, @ErrMsg = dbo.Aff_f_GetMessageById(305, @Language)
			RETURN
		END

		IF @Status = 'Approved'
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM dbo.AffInfo ai1 WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai2 WITH (NOLOCK) ON ai1.Email = ai2.Email AND ai1.AffId <> ai2.AffId
				WHERE ai1.AffId = @AffId
					AND ai2.Status = 'Approved'
			)
			BEGIN
				-- Email Address has been used. Please choose another one!
				SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
				RETURN
			END

			IF NOT EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId AND GroupId = @GroupId)
			BEGIN
				-- Invalid Commission Group
				SELECT @ErrCode = 1007, @ErrMsg = dbo.Aff_f_GetMessageById(601, @Language)
				RETURN
			END
		END

		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET Status = ISNULL(@Status, Status),
				ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN @CurrentDate ELSE NULL END,
				CasinoJoinedDate = @CurrentDate
			OUTPUT	DELETED.Status, DELETED.ApprovedDate, DELETED.CasinoJoinedDate,
					INSERTED.Status, INSERTED.ApprovedDate, INSERTED.CasinoJoinedDate
			INTO @UpdatedData (Status_Del, ApprovedDate_Del, CasinoJoinedDate_Del,
								Status_Ins, ApprovedDate_Ins, CasinoJoinedDate_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData =
					'Status='			+ ISNULL(Status_Del, '') + ',' + 
					'ApprovedDate='		+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Del), '') + ',' + 
					'CasinoJoinedDate=' + ISNULL(CONVERT(VARCHAR(20), CasinoJoinedDate_Del), ''),
				@NewData =
					'Status='			+ ISNULL(Status_Ins, '') + ',' + 
					'ApprovedDate='		+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Ins), '') + ',' + 
					'CasinoJoinedDate=' + ISNULL(CONVERT(VARCHAR(20), CasinoJoinedDate_Ins), '')
		FROM @UpdatedData
	END
	-- Update Close only (Left menu)
	ELSE IF @Closed IS NOT NULL
	BEGIN
		IF @Closed = 1
		BEGIN
			DECLARE @NoCommGroupId INT, @AffIds VARCHAR(MAX)
			SELECT  @NoCommGroupId = GroupId, @AffIds = CONVERT(VARCHAR(20), @AffId)
			FROM dbo.CommGroup WITH (NOLOCK)
			WHERE GroupName = 'NoCommission'

			DECLARE @RefNo INT = 0

			EXEC dbo.Aff_CommGroupAssign
				@UserId = @UserId,
				@GroupId = @NoCommGroupId,
				@AffIdList = @AffIds,
				@IP = @IP,
				--@Language = @Language,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT,
				@RefNo = @RefNo OUTPUT

			IF @ErrCode <> 0
			BEGIN
				-- Update process is unsuccessful. Please try again!
				SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
				RETURN
			END
		END
		ELSE
		BEGIN
			-- Reset Login Count (no need to writelog)
			UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
			SET LoginCount = 0
			WHERE AffId = @AffId
		END

		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET IsClosed = ISNULL(@Closed, IsClosed)
			OUTPUT DELETED.IsClosed, INSERTED.IsClosed
			INTO @UpdatedData (Closed_Del, Closed_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		SELECT	@OldData = 'IsClose=' + ISNULL(CONVERT(VARCHAR(1), Closed_Del), ''),
				@NewData = 'IsClose=' + ISNULL(CONVERT(VARCHAR(1), Closed_Ins), '')
		FROM @UpdatedData
	END
	-- Update others (Edit tab)
	ELSE
	BEGIN
		-- Check if change player_username
		IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffId AND Player_Username <> @PlayerUsername)
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffId AND Status = 'Pending')
			BEGIN
				-- Oops, this account is having 1 pending pay out request, please update this transaction first!
				SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)
				RETURN
			END
		END

		-- Check duplicate email
		IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId <> @AffId AND Email = @Email AND Status <> 'Disapproved')
		BEGIN
			-- Email Address has been used. Please choose another one!
			SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
			RETURN
		END

		DECLARE @Player_IBCCustId INT
		SELECT  @Player_IBCCustId = custid
		FROM DBEXT.bodb02.dbo.Customer WITH (NOLOCK)
		WHERE username2 = '12BET$' + @PlayerUsername

		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET FirstName = ISNULL(@FirstName, FirstName),
				LastName = ISNULL(@LastName, LastName),
				Email = ISNULL(@Email, Email)
			OUTPUT	DELETED.FirstName, DELETED.LastName, DELETED.Email,
					INSERTED.FirstName, INSERTED.LastName, INSERTED.Email
			INTO @UpdatedData (FirstName_Del, LastName_Del, Email_Del,
								FirstName_Ins, LastName_Ins, Email_Ins)
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		BEGIN TRY
			UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
			SET Gender = ISNULL(@Gender, Gender),
				Country = ISNULL(@Country, Country),
				Phone = ISNULL(@Phone, Phone),
				ContactApps = ISNULL(@ContactApps, ContactApps),
				Address = ISNULL(@Address, Address),
				City = ISNULL(@City, City),
				State = ISNULL(@State, State),
				Postal = ISNULL(@Postal, Postal),
				SiteURL = ISNULL(@SiteURL, SiteURL),
				MoreSiteURLs = ISNULL(@MoreSiteURLs, MoreSiteURLs),
				NoSiteDesc = ISNULL(@NoSiteDesc, NoSiteDesc),
				PreferredLanguage = ISNULL(@PreferredLanguage, PreferredLanguage),
				PreferredPayment = ISNULL(@PreferredPayment, PreferredPayment),
				Player_IBCCustId = ISNULL(@Player_IBCCustId, Player_IBCCustId),
				Player_Username = ISNULL(@PlayerUsername, Player_Username),
				Neteller_AccountId = ISNULL(@NetellerAccountId, Neteller_AccountId),
				Moneybookers_Email = ISNULL(@MoneybookersEmail, Moneybookers_Email),
				Wire_BankName = ISNULL(@BankName, Wire_BankName),
				Wire_BankAddress = ISNULL(@BankAddress, Wire_BankAddress),
				Wire_SwiftCode = ISNULL(@BankSwiftCode, Wire_SwiftCode),
				Wire_AccountName = ISNULL(@BankAccountName, Wire_AccountName),
				Wire_AccountNo = ISNULL(@BankAccountNo, Wire_AccountNo),
				MailOption = ISNULL(@MailOption, MailOption),
				QuestionId = ISNULL(@QuestionId, QuestionId),
				Answer = ISNULL(@Answer, Answer)
			OUTPUT	DELETED.Gender,DELETED.Country,DELETED.Phone,DELETED.ContactApps,
					DELETED.Address,DELETED.City,DELETED.State,DELETED.Postal,
					DELETED.SiteURL,DELETED.MoreSiteURLs,DELETED.NoSiteDesc,DELETED.PreferredPayment,
					DELETED.Player_IBCCustId,DELETED.Player_Username,DELETED.Neteller_AccountId,DELETED.Moneybookers_Email,
					DELETED.Wire_BankName,DELETED.Wire_BankAddress,DELETED.Wire_SwiftCode,DELETED.Wire_AccountName,
					DELETED.Wire_AccountNo,DELETED.MailOption,DELETED.QuestionId,DELETED.Answer,
					INSERTED.Gender,INSERTED.Country,INSERTED.Phone,INSERTED.ContactApps,
					INSERTED.Address,INSERTED.City,INSERTED.State,INSERTED.Postal,
					INSERTED.SiteURL,INSERTED.MoreSiteURLs,INSERTED.NoSiteDesc,INSERTED.PreferredPayment,
					INSERTED.Player_IBCCustId,INSERTED.Player_Username,INSERTED.Neteller_AccountId,INSERTED.Moneybookers_Email,
					INSERTED.Wire_BankName,INSERTED.Wire_BankAddress,INSERTED.Wire_SwiftCode,INSERTED.Wire_AccountName,
					INSERTED.Wire_AccountNo,INSERTED.MailOption,INSERTED.QuestionId,INSERTED.Answer
			INTO @UpdatedData
			(
					Gender_Del,Country_Del,Phone_Del,ContactApps_Del,
					Address_Del,City_Del,State_Del,Postal_Del,
					SiteURL_Del,MoreSiteURLs_Del,NoSiteDesc_Del,PreferredPayment_Del,
					Player_IBCCustId_Del,Player_Username_Del,Neteller_AccountId_Del,Moneybookers_Email_Del,
					Wire_BankName_Del,Wire_BankAddress_Del,Wire_SwiftCode_Del,Wire_AccountName_Del,
					Wire_AccountNo_Del,MailOption_Del,QuestionId_Del,Answer_Del,
					Gender_Ins,Country_Ins,Phone_Ins,ContactApps_Ins,
					Address_Ins,City_Ins,State_Ins,Postal_Ins,
					SiteURL_Ins,MoreSiteURLs_Ins,NoSiteDesc_Ins,PreferredPayment_Ins,
					Player_IBCCustId_Ins,Player_Username_Ins,Neteller_AccountId_Ins,Moneybookers_Email_Ins,
					Wire_BankName_Ins,Wire_BankAddress_Ins,Wire_SwiftCode_Ins,Wire_AccountName_Ins,
					Wire_AccountNo_Ins,MailOption_Ins,QuestionId_Ins,Answer_Ins
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
					'MailOption='			+ ISNULL(CONVERT(VARCHAR(1), MailOption_Del), '') + ',' +
					'QuestionId='			+ ISNULL(CONVERT(VARCHAR(3), QuestionId_Del), '') + ',' +
					'Answer='				+ ISNULL(Answer_Del, ''),
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
					'MailOption='			+ ISNULL(CONVERT(VARCHAR(1), MailOption_Ins), '') + ',' +
					'QuestionId='			+ ISNULL(CONVERT(VARCHAR(3), QuestionId_Ins), '') + ',' +
					'Answer='				+ ISNULL(Answer_Ins, '')
		FROM @UpdatedData
	END
	
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