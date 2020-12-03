/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
	@MailOption			BIT = NULL,
	@SiteURL			VARCHAR(100) = NULL,
	@MoreSiteURLs		VARCHAR(1000) = NULL,
	@NoSiteDesc			NVARCHAR(1000) = NULL,
	-- Payment Information: Player, Neteller, Moneybookers, Bank Transfer
	@PreferredPayment	VARCHAR(20) = NULL,
		-- Player
	@Player_CustId		INT = NULL,
	@Player_Username	NVARCHAR(50) = NULL,
	@Player_Currency	INT = NULL,
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
	Creator: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task:
		Admin site - Customer - Edit - Update Info (Exclude Preferrence Language and Password)
		Admin site - Customer - Left menu - Update Preferrence Language / Password
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201026@Percy: Add AffCode - auto generate code when affiliate was approved [RedmineID: #143852]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
	SELECT  @CurrentDate = GETDATE()

	DECLARE @AffCode VARCHAR(20)

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserID,
		@FuncName	= '[Affiliate]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT

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
		ApprovedBy_Del			INT,
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
		Player_CustId_Del		INT,
		Player_Username_Del		NVARCHAR(50),
		Player_Currency_Del		INT,
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
		ApprovedBy_Ins			INT,
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
		Player_CustId_Ins		INT,
		Player_Username_Ins		NVARCHAR(50),
		Player_Currency_Ins		INT,
		Neteller_AccountId_Ins	VARCHAR(50),
		Moneybookers_Email_Ins	NVARCHAR(50),
		Wire_BankName_Ins		NVARCHAR(100),
		Wire_BankAddress_Ins	NVARCHAR(200),
		Wire_SwiftCode_Ins		NVARCHAR(50),
		Wire_AccountName_Ins	NVARCHAR(100),
		Wire_AccountNo_Ins		VARCHAR(100),
		MailOption_Ins			BIT
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

			;WITH CTE_AffCode AS
			(
				SELECT TOP 1 * FROM dbo.AffiliateCode WITH (ROWLOCK)
				WHERE AffId IS NULL
				ORDER BY NEWID() -- random
			)
			UPDATE CTE_AffCode
			SET AffId = @AffId

			SELECT @AffCode = AffCode FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffId = @AffId
		END

		BEGIN TRY
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET Status = ISNULL(@Status, Status),
				ApprovedDate = CASE WHEN @Status IN ('Approved', 'Disapproved') THEN @CurrentDate ELSE NULL END,
				ApprovedBy = @UserId,
				AffCode = ISNULL(@AffCode, AffCode)
			OUTPUT	DELETED.Status, DELETED.ApprovedDate, DELETED.ApprovedBy,
					INSERTED.Status, INSERTED.ApprovedDate, INSERTED.ApprovedBy
			INTO @UpdatedData (Status_Del, ApprovedDate_Del, ApprovedBy_Del,
								Status_Ins, ApprovedDate_Ins, ApprovedBy_Ins)
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
					'ApprovedBy='		+ ISNULL(u1.UserName, ''),
				@NewData =
					'Status='			+ ISNULL(Status_Ins, '') + ',' + 
					'ApprovedDate='		+ ISNULL(CONVERT(VARCHAR(20), ApprovedDate_Ins), '') + ',' + 
					'ApprovedBy='		+ ISNULL(u2.UserName, '')
		FROM @UpdatedData ud
			LEFT JOIN dbo.Affiliate_User u1 WITH (NOLOCK) ON ud.ApprovedBy_Del = u1.CustId
			LEFT JOIN dbo.Affiliate_User u2 WITH (NOLOCK) ON ud.ApprovedBy_Ins = u2.CustId
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

			EXEC dbo.Aff_Admin_CommGroup_Assign
				@UserId		= @UserId,
				@AffId		= @AffId,
				@GroupId	= @NoCommGroupId,
				@IP			= @IP,
				@ErrCode	= @ErrCode OUTPUT,
				@ErrMsg		= @ErrMsg OUTPUT

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
		IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffId AND Player_Username <> @Player_Username)
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffId AND Status = 'Pending')
			BEGIN
				-- Oops, this account is having 1 pending pay out request, please update this transaction first!
				SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)
				RETURN
			END

			-- Check exists player_username
			IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE Player_Username = @Player_UserName AND AffID <> @AffId)
			BEGIN
				-- Player Username has been used. Please choose another one!
				SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(3, @Language)

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

		DECLARE @Player_CurrencyName NVARCHAR(50), @Player_CurrencyCode VARCHAR(3)
		SELECT  @Player_CurrencyName = currency, @Player_CurrencyCode = CASE WHEN ExchangeId = 20 THEN 'UUS' ELSE Code END
		FROM bodb02.dbo.Exchange WITH (NOLOCK)
		WHERE ExchangeId = @Player_Currency

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
				PreferredPayment = @PreferredPayment,
				Player_CustId = ISNULL(@Player_CustId, Player_CustId),
				Player_Username = ISNULL(@Player_Username, Player_Username),
				Player_Currency = ISNULL(@Player_Currency, Player_Currency),
				Player_CurrencyName = ISNULL(@Player_CurrencyName, Player_CurrencyName),
				Player_CurrencyCode = ISNULL(@Player_CurrencyCode, Player_CurrencyCode),
				MailOption = ISNULL(@MailOption, MailOption)
			OUTPUT	DELETED.Gender,DELETED.Country,DELETED.Phone,DELETED.ContactApps,DELETED.Address,DELETED.City,DELETED.State,DELETED.Postal,
					DELETED.SiteURL,DELETED.MoreSiteURLs,DELETED.NoSiteDesc,DELETED.PreferredLanguage,DELETED.PreferredPayment,
					DELETED.Player_CustId,DELETED.Player_Username,DELETED.Player_Currency,DELETED.MailOption,
					INSERTED.Gender,INSERTED.Country,INSERTED.Phone,INSERTED.ContactApps,INSERTED.Address,INSERTED.City,INSERTED.State,INSERTED.Postal,
					INSERTED.SiteURL,INSERTED.MoreSiteURLs,INSERTED.NoSiteDesc,INSERTED.PreferredLanguage,INSERTED.PreferredPayment,
					INSERTED.Player_CustId,INSERTED.Player_Username,INSERTED.Player_Currency,INSERTED.MailOption
			INTO @UpdatedData
			(
					Gender_Del,Country_Del,Phone_Del,ContactApps_Del,Address_Del,City_Del,State_Del,Postal_Del,
					SiteURL_Del,MoreSiteURLs_Del,NoSiteDesc_Del,PreferredLanguage_Del,PreferredPayment_Del,
					Player_CustId_Del,Player_Username_Del,Player_Currency_Del,MailOption_Del,
					Gender_Ins,Country_Ins,Phone_Ins,ContactApps_Ins,Address_Ins,City_Ins,State_Ins,Postal_Ins,
					SiteURL_Ins,MoreSiteURLs_Ins,NoSiteDesc_Ins,PreferredLanguage_Ins,PreferredPayment_Ins,
					Player_CustId_Ins,Player_Username_Ins,Player_Currency_Ins,MailOption_Ins
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
					'PreferredLanguage='	+ ISNULL(PreferredLanguage_Del, '') + ',' +
					'Player_CustId='		+ ISNULL(CONVERT(VARCHAR(15), Player_CustId_Del), '') + ',' +
					'Player_Username='		+ ISNULL(Player_Username_Del, '') + ',' +
					'Player_Currency='		+ ISNULL(CONVERT(VARCHAR(10), Player_Currency_Del), '') + ',' +
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
					'PreferredPayment='		+ ISNULL(PreferredPayment_Ins, '') + ',' +
					'PreferredLanguage='	+ ISNULL(PreferredLanguage_Ins, '') + ',' +
					'Player_CustId='		+ ISNULL(CONVERT(VARCHAR(15), Player_CustId_Ins), '') + ',' +
					'Player_Username='		+ ISNULL(Player_Username_Ins, '') + ',' +
					'Player_Currency='		+ ISNULL(CONVERT(VARCHAR(10), Player_Currency_Ins), '') + ',' +
					'MailOption='			+ ISNULL(CONVERT(VARCHAR(1), MailOption_Ins), '')
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