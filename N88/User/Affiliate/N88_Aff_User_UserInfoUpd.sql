/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoUpd]
	@AffId					INT,
	@UserId					INT,
	@Phone					VARCHAR(50) = NULL,
	@ContactApps			NVARCHAR(2000) = NULL,
	@SiteURL				VARCHAR(100) = NULL,
	@MoreSiteURLs			VARCHAR(1000) = NULL,
	@NoSiteDesc				NVARCHAR(1000) = NULL,
	@Player_Username		NVARCHAR(50) = NULL,
	@DefaultBaseCurrency	INT = NULL,
	@Language				NVARCHAR(20) = 'en-US',
	@IP						VARCHAR(50),
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(2000) = '' OUTPUT
AS  

/*
	Creator: 20180601@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: User - My Account - Update user info
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteName VARCHAR(30)
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName')

	-- Check if change player_username
	IF EXISTS (SELECT 1 FROM dbo.AffDetail WITH (NOLOCK) WHERE AffID = @AffId AND Player_Username <> @Player_Username)
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.AffPayout WITH (NOLOCK) WHERE AffID = @AffId AND Status = 'Pending')
		BEGIN
			-- Oops, this account is having 1 pending pay out request, please update this transaction first!
			SELECT @ErrCode = 1001, @ErrMsg = dbo.Aff_f_GetMessageById(301, @Language)

			RETURN
		END
	END

	DECLARE @Player_IBCCustId INT
	SELECT  @Player_IBCCustId = custid
	FROM bodb02.dbo.Customer WITH (NOLOCK)
	WHERE username2 = @SiteName + '$' + @Player_Username

	DECLARE @UpdatedData TABLE
	(
		-- del
		Phone_Del				VARCHAR(50),
		ContactApps_Del			NVARCHAR(2000),
		SiteURL_Del				VARCHAR(100),
		MoreSiteURLs_Del		VARCHAR(1000),
		NoSiteDesc_Del			NVARCHAR(1000),
		PreferredPayment_Del	VARCHAR(20),
		Player_IBCCustId_Del	INT,
		Player_Username_Del		NVARCHAR(100),
		DefaultCurrency_Del		INT,
		-- insert
		Phone_Ins				NVARCHAR(50),
		ContactApps_Ins			NVARCHAR(2000),
		SiteURL_Ins				VARCHAR(100),
		MoreSiteURLs_Ins		VARCHAR(1000),
		NoSiteDesc_Ins			NVARCHAR(1000),
		PreferredPayment_Ins	VARCHAR(20),
		Player_IBCCustId_Ins	INT,
		Player_Username_Ins		NVARCHAR(100),
		DefaultCurrency_Ins		INT
	)

	BEGIN TRY
		IF @DefaultBaseCurrency IS NOT NULL
			UPDATE dbo.AffInfo WITH (ROWLOCK)
			SET DefaultCurrency = @DefaultBaseCurrency
			OUTPUT
				DELETED.DefaultCurrency,
				INSERTED.DefaultCurrency
			INTO @UpdatedData
			(
				DefaultCurrency_Del,
				DefaultCurrency_Ins
			)
			WHERE AffId = @AffId

		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET Phone				= ISNULL(@Phone, Phone),
			ContactApps			= ISNULL(@ContactApps, ContactApps),
			SiteURL				= ISNULL(@SiteURL, SiteURL),
			MoreSiteURLs		= ISNULL(@MoreSiteURLs, MoreSiteURLs),
			NoSiteDesc			= ISNULL(@NoSiteDesc, NoSiteDesc),
			PreferredPayment	= 'Player', -- default user update
			Player_IBCCustId	= ISNULL(@Player_IBCCustId, Player_IBCCustId),
			Player_Username		= ISNULL(@Player_Username, Player_Username)
		OUTPUT
			DELETED.Phone,
			DELETED.ContactApps,
			DELETED.SiteURL,
			DELETED.MoreSiteURLs,
			DELETED.NoSiteDesc,
			DELETED.PreferredPayment,
			DELETED.Player_IBCCustId,
			DELETED.Player_Username,
			INSERTED.Phone,
			INSERTED.ContactApps,
			INSERTED.SiteURL,
			INSERTED.MoreSiteURLs,
			INSERTED.NoSiteDesc,
			INSERTED.PreferredPayment,
			INSERTED.Player_IBCCustId,
			INSERTED.Player_Username
		INTO @UpdatedData
		(
			Phone_Del,
			ContactApps_Del,
			SiteURL_Del,
			MoreSiteURLs_Del,
			NoSiteDesc_Del,
			PreferredPayment_Del,
			Player_IBCCustId_Del,
			Player_Username_Del,
			Phone_Ins,
			ContactApps_Ins,
			SiteURL_Ins,
			MoreSiteURLs_Ins,
			NoSiteDesc_Ins,
			PreferredPayment_Ins,
			Player_IBCCustId_Ins,
			Player_Username_Ins
		)
		WHERE AffID = @AffId
	END TRY
	BEGIN CATCH
		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	SELECT  @OldData =
		'Phone='			+ ISNULL(Phone_Del, '') + ',' +
		'ContactApps='		+ ISNULL(ContactApps_Del, '') + ',' +
		'SiteURL='			+ ISNULL(SiteURL_Del, '') + ',' +
		'MoreSiteURLs='		+ ISNULL(MoreSiteURLs_Del, '') + ',' +
		'NoSiteDesc='		+ ISNULL(NoSiteDesc_Del, '') + ',' +
		'PreferredPayment='	+ ISNULL(PreferredPayment_Del, '') + ',' +
		'Player_IBCCustId=' + ISNULL(CONVERT(VARCHAR(15), Player_IBCCustId_Del), '') + ',' +
		'Player_Username='	+ ISNULL(Player_Username_Del, '') + ',' + 
		'DefaultCurrency='	+ ISNULL(CONVERT(VARCHAR(10), DefaultCurrency_Del), '')
	FROM @UpdatedData

	SELECT  @NewData =
		'Phone='			+ ISNULL(Phone_Ins, '') + ',' +
		'ContactApps='		+ ISNULL(ContactApps_Ins, '') + ',' +
		'SiteURL='			+ ISNULL(SiteURL_Ins, '') + ',' +
		'MoreSiteURLs='		+ ISNULL(MoreSiteURLs_Ins, '') + ',' +
		'NoSiteDesc='		+ ISNULL(NoSiteDesc_Ins, '') + ',' +
		'PreferredPayment='	+ ISNULL(PreferredPayment_Ins, '') + ',' +
		'Player_IBCCustId='	+ ISNULL(CONVERT(VARCHAR(15), Player_IBCCustId_Ins), '') + ',' +
		'Player_Username='	+ ISNULL(Player_Username_Ins, '') + ',' + 
		'DefaultCurrency='	+ ISNULL(CONVERT(VARCHAR(10), DefaultCurrency_Ins), '')
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