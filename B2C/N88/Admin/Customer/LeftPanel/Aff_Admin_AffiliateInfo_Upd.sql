/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
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
	@IP					VARCHAR(50),
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS  

/*
	Creator: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:
		Admin site - Customer - Edit - Update Info (Exclude Preferrence Language and Password)
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201026@Percy: Add AffCode - auto generate code when affiliate was approved [RedmineID: #143852]
		- 20200107@Percy: Add suspended status [RedmineID: #148373]
		- 20201215@Percy: Add AffMediaLink [RedmineID: #146201]
		- 20210223@Percy: Do not update ApprovedDate if change from Suspended [RedmineID: #150493]
		- 20230523@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
		- 20240828@Sally: Add new permission for approve new affiliate [RedmineID: #209858]
		- 20250623@Sally: valid Affiliate account by Affcategory [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @CurrentDate SMALLDATETIME
		,@Language VARCHAR(20)
		,@AffCategoryId INT = 1 -- default normal affiliate account

	SELECT @CurrentDate = GETDATE()
	SELECT @Language	= 'en-US'

	DECLARE @AffCode VARCHAR(20)

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[EditAffiliateDetails]',
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

	-- Separate table variables for old and new data logging
	DECLARE @OldDataTable TABLE
	(
		FirstName			NVARCHAR(50),
		LastName			NVARCHAR(50),
		Email				NVARCHAR(50),
		Gender				BIT,
		Country				NVARCHAR(50),
		Phone				VARCHAR(50),
		ContactApps			NVARCHAR(2000),
		Address				NVARCHAR(250),
		City				NVARCHAR(250),
		State				NVARCHAR(50),
		Postal				NVARCHAR(50),
		SiteURL				VARCHAR(100),
		MoreSiteURLs		VARCHAR(1000),
		NoSiteDesc			NVARCHAR(1000),
		PreferredPayment	VARCHAR(20),
		Player_CustId		INT,
		Player_Username		NVARCHAR(50),
		Player_Currency		INT,
		Player_CurrencyName	NVARCHAR(50),
		Player_CurrencyCode	VARCHAR(3),
		MailOption			BIT
	)

	DECLARE @NewDataTable TABLE
	(
		FirstName			NVARCHAR(50),
		LastName			NVARCHAR(50),
		Email				NVARCHAR(50),
		Gender				BIT,
		Country				NVARCHAR(50),
		Phone				VARCHAR(50),
		ContactApps			NVARCHAR(2000),
		Address				NVARCHAR(250),
		City				NVARCHAR(250),
		State				NVARCHAR(50),
		Postal				NVARCHAR(50),
		SiteURL				VARCHAR(100),
		MoreSiteURLs		VARCHAR(1000),
		NoSiteDesc			NVARCHAR(1000),
		PreferredPayment	VARCHAR(20),
		Player_CustId		INT,
		Player_Username		NVARCHAR(50),
		Player_Currency		INT,
		Player_CurrencyName	NVARCHAR(50),
		Player_CurrencyCode	VARCHAR(3),
		MailOption			BIT
	)

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	-- Update others (Edit tab)
	BEGIN
		-- Check if change player_username
		IF EXISTS (
			SELECT 1 
			FROM dbo.AffDetail WITH (NOLOCK) 
			WHERE AffID = @AffId 
				AND ISNULL(Player_Username, '') <> ISNULL(@Player_Username,'')
		)
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffId AND Status = 'Pending')
			BEGIN
				-- Oops, this account is having 1 pending pay out request, please update this transaction first!
				SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)
				RETURN
			END

			-- Check exists player_username
			IF EXISTS (SELECT 1 
				FROM dbo.AffDetail WITH (NOLOCK) 
				WHERE Player_Username = @Player_Username 
					AND ISNULL(Player_Username, '') <> '' 
					AND AffID <> @AffId
			)
			BEGIN
				-- Player Username has been used. Please choose another one!
				SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(3, @Language)

				RETURN
			END
		END

		-- Get category of affiliate
		SELECT @AffCategoryId  = AffCategoryId
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE AffId = @AffId

		-- Error shows Message if user edit to an existed email Address of Normal AFF account 
		IF EXISTS (
			SELECT 1 
			FROM dbo.AffInfo WITH (NOLOCK) 
			WHERE AffId <> @AffId 
				AND Email = @Email 
				AND Status <> 'Disapproved' 
				AND (
					(AffCategoryId = 1 AND @AffCategoryId = 2)
					OR
					(@AffCategoryId = 1)
				)
		)
		BEGIN
			-- Email Address has been used. Please choose another one!
			SELECT @ErrCode = 1002, @ErrMsg = dbo.Aff_f_GetMessageById(1, @Language)
			RETURN
		END

		DECLARE @Player_CurrencyName NVARCHAR(50), @Player_CurrencyCode VARCHAR(3), @Player_ExchangeId INT = @Player_Currency

		---Get player currency mapping
		IF @Player_Currency IS NOT NULL
		BEGIN
			SELECT @Player_ExchangeId = t.ExchangeId
			FROM dbo.TpExchange t WITH (NOLOCK)
			WHERE t.TpExchangeId = @Player_Currency

			SELECT  @Player_CurrencyName = currency, @Player_CurrencyCode = CASE WHEN e.ExchangeId = 20 THEN 'UUS' ELSE Code END
			FROM bodb02.dbo.Exchange e WITH (NOLOCK)
			WHERE e.ExchangeId = @Player_ExchangeId
		END


		-- Capture current data before UPDATE (Old Data)
		INSERT INTO @OldDataTable (
			FirstName,
			LastName,
			Email,
			Gender,
			Country,
			Phone,
			ContactApps,
			Address,
			City,
			State,
			Postal,
			SiteURL,
			MoreSiteURLs,
			NoSiteDesc,
			PreferredPayment,
			Player_CustId,
			Player_Username,
			Player_Currency,
			Player_CurrencyName,
			Player_CurrencyCode,
			MailOption
		)
		SELECT ai.FirstName,
			   ai.LastName,
			   ai.Email,
			   ad.Gender,
			   ad.Country,
			   ad.Phone,
			   ad.ContactApps,
			   ad.Address,
			   ad.City,
			   ad.State,
			   ad.Postal,
			   ad.SiteURL,
			   ad.MoreSiteURLs,
			   ad.NoSiteDesc,
			   ad.PreferredPayment,
			   ad.Player_CustId,
			   ad.Player_Username,
			   ad.Player_Currency,
			   ad.Player_CurrencyName,
			   ad.Player_CurrencyCode,
			   ad.MailOption
		FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		WHERE ai.AffId = @AffId;

		-- Capture new data from parameters (New Data)
		INSERT INTO @NewDataTable (
			FirstName,
			LastName,
			Email,
			Gender,
			Country,
			Phone,
			ContactApps,
			Address,
			City,
			State,
			Postal,
			SiteURL,
			MoreSiteURLs,
			NoSiteDesc,
			PreferredPayment,
			Player_CustId,
			Player_Username,
			Player_Currency,
			Player_CurrencyName,
			Player_CurrencyCode,
			MailOption
		)
		SELECT @FirstName,
			   @LastName,
			   @Email,
			   @Gender,
			   @Country,
			   @Phone,
			   @ContactApps,
			   @Address,
			   @City,
			   @State,
			   @Postal,
			   @SiteURL,
			   @MoreSiteURLs,
			   @NoSiteDesc,
			   @PreferredPayment,
			   @Player_CustId,
			   @Player_Username,
			   @Player_Currency,
			   @Player_CurrencyName,
			   @Player_CurrencyCode,
			   @MailOption;

		BEGIN TRY
			-- Update AffInfo table
			UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
			SET FirstName = @FirstName,
				LastName = @LastName,
				Email = @Email
			WHERE AffId = @AffId

			-- Update AffDetail table
			UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)
			SET Gender = @Gender,
				Country = @Country,
				Phone = @Phone,
				ContactApps = @ContactApps,
				Address = @Address,
				City = @City,
				State = @State,
				Postal = @Postal,
				SiteURL = @SiteURL,
				MoreSiteURLs = @MoreSiteURLs,
				NoSiteDesc = @NoSiteDesc,
				PreferredPayment = @PreferredPayment,
				Player_CustId = @Player_CustId,
				Player_Username = @Player_Username,
				Player_Currency = @Player_Currency,
				Player_CurrencyName = @Player_CurrencyName,
				Player_CurrencyCode = @Player_CurrencyCode,
				MailOption = @MailOption
			WHERE AffId = @AffId
		END TRY
		BEGIN CATCH
			-- Rollback manually using old data from @OldDataTable
			UPDATE ai WITH (ROWLOCK, UPDLOCK)
			SET FirstName = od.FirstName,
				LastName = od.LastName,
				Email = od.Email
			FROM dbo.AffInfo ai
				CROSS JOIN @OldDataTable od
			WHERE ai.AffId = @AffId

			UPDATE ad WITH (ROWLOCK, UPDLOCK)
			SET Gender = od.Gender,
				Country = od.Country,
				Phone = od.Phone,
				ContactApps = od.ContactApps,
				Address = od.Address,
				City = od.City,
				State = od.State,
				Postal = od.Postal,
				SiteURL = od.SiteURL,
				MoreSiteURLs = od.MoreSiteURLs,
				NoSiteDesc = od.NoSiteDesc,
				PreferredPayment = od.PreferredPayment,
				Player_CustId = od.Player_CustId,
				Player_Username = od.Player_Username,
				Player_Currency = od.Player_Currency,
				Player_CurrencyName = od.Player_CurrencyName,
				Player_CurrencyCode = od.Player_CurrencyCode,
				MailOption = od.MailOption
			FROM dbo.AffDetail ad
				CROSS JOIN @OldDataTable od
			WHERE ad.AffId = @AffId

			-- After rollback, refresh @NewDataTable from actual table data
			DELETE FROM @NewDataTable;
			INSERT INTO @NewDataTable (
				FirstName,
				LastName,
				Email,
				Gender,
				Country,
				Phone,
				ContactApps,
				Address,
				City,
				State,
				Postal,
				SiteURL,
				MoreSiteURLs,
				NoSiteDesc,
				PreferredPayment,
				Player_CustId,
				Player_Username,
				Player_Currency,
				Player_CurrencyName,
				Player_CurrencyCode,
				MailOption
			)
			SELECT ai.FirstName,
				   ai.LastName,
				   ai.Email,
				   ad.Gender,
				   ad.Country,
				   ad.Phone,
				   ad.ContactApps,
				   ad.Address,
				   ad.City,
				   ad.State,
				   ad.Postal,
				   ad.SiteURL,
				   ad.MoreSiteURLs,
				   ad.NoSiteDesc,
				   ad.PreferredPayment,
				   ad.Player_CustId,
				   ad.Player_Username,
				   ad.Player_Currency,
				   ad.Player_CurrencyName,
				   ad.Player_CurrencyCode,
				   ad.MailOption
			FROM dbo.AffInfo ai WITH (NOLOCK)
			LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			WHERE ai.AffId = @AffId;

			-- Update process is unsuccessful. Please try again!
			SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
			RETURN
		END CATCH

		-- Build log strings from separate Old and New data tables
		SELECT	@OldData =
				'FirstName=' + ISNULL(FirstName, '') + ',' +
				'LastName=' + ISNULL(LastName, '') + ',' +
				'Email=' + ISNULL(Email, '') + ',' +
				'Gender=' + ISNULL(CONVERT(VARCHAR(1), Gender), '') + ',' +
				'Country=' + ISNULL(Country, '') + ',' +
				'Phone=' + ISNULL(Phone, '') + ',' +
				'ContactApps=' + ISNULL(ContactApps, '') + ',' +
				'Address=' + ISNULL(Address, '') + ',' +
				'City=' + ISNULL(City, '') + ',' +
				'State=' + ISNULL(State, '') + ',' +
				'Postal=' + ISNULL(Postal, '') + ',' +
				'SiteURL=' + ISNULL(SiteURL, '') + ',' +
				'MoreSiteURLs=' + ISNULL(MoreSiteURLs, '') + ',' +
				'NoSiteDesc=' + ISNULL(NoSiteDesc, '') + ',' +
				'PreferredPayment=' + ISNULL(PreferredPayment, '') + ',' +
				'Player_CustId=' + ISNULL(CONVERT(VARCHAR(15), Player_CustId), '') + ',' +
				'Player_Username=' + ISNULL(Player_Username, '') + ',' +
				'Player_Currency=' + ISNULL(CONVERT(VARCHAR(10), Player_Currency), '') + ',' +
				'MailOption=' + ISNULL(CONVERT(VARCHAR(1), MailOption), '')
		FROM @OldDataTable

		SELECT	@NewData =
				'FirstName=' + ISNULL(FirstName, '') + ',' +
				'LastName=' + ISNULL(LastName, '') + ',' +
				'Email=' + ISNULL(Email, '') + ',' +
				'Gender=' + ISNULL(CONVERT(VARCHAR(1), Gender), '') + ',' +
				'Country=' + ISNULL(Country, '') + ',' +
				'Phone=' + ISNULL(Phone, '') + ',' +
				'ContactApps=' + ISNULL(ContactApps, '') + ',' +
				'Address=' + ISNULL(Address, '') + ',' +
				'City=' + ISNULL(City, '') + ',' +
				'State=' + ISNULL(State, '') + ',' +
				'Postal=' + ISNULL(Postal, '') + ',' +
				'SiteURL=' + ISNULL(SiteURL, '') + ',' +
				'MoreSiteURLs=' + ISNULL(MoreSiteURLs, '') + ',' +
				'NoSiteDesc=' + ISNULL(NoSiteDesc, '') + ',' +
				'PreferredPayment=' + ISNULL(PreferredPayment, '') + ',' +
				'Player_CustId=' + ISNULL(CONVERT(VARCHAR(15), Player_CustId), '') + ',' +
				'Player_Username=' + ISNULL(Player_Username, '') + ',' +
				'Player_Currency=' + ISNULL(CONVERT(VARCHAR(10), Player_Currency), '') + ',' +
				'MailOption=' + ISNULL(CONVERT(VARCHAR(1), MailOption), '')
		FROM @NewDataTable
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