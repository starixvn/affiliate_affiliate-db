/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_UserInfoUpd]
	@AffId					INT,
	@UserId					INT,
	@Phone					VARCHAR(50) = NULL,
	@ContactApps			NVARCHAR(2000) = NULL,
	@SiteURL				VARCHAR(100) = NULL,
	@MoreSiteURLs			VARCHAR(1000) = NULL,
	@NoSiteDesc				NVARCHAR(1000) = NULL,
	@DefaultBaseCurrency	INT = NULL,
	@Language				NVARCHAR(20) = 'en-US',
	@IP						VARCHAR(50),
	@ErrCode				INT = 0 OUTPUT,
	@ErrMsg					NVARCHAR(2000) = '' OUTPUT,
	@TargetCountryCode		VARCHAR(5) = ''
AS  

/*
	Creator: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User - My Account - Update user info
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
        - 20250707@Sally: Get info Affcategory [RedmineID: #212201]
		- 20250729@Danny: Add TargetCountry [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON
	
	-- Separate table variables for old and new data logging
	DECLARE @OldDataTable TABLE
	(
		Phone				VARCHAR(50),
		ContactApps			NVARCHAR(2000),
		SiteURL				VARCHAR(100),
		MoreSiteURLs		VARCHAR(1000),
		NoSiteDesc			NVARCHAR(1000),
		DefaultCurrency		INT,
		TargetCountryCode	VARCHAR(5)
	)

	DECLARE @NewDataTable TABLE
	(
		Phone				VARCHAR(50),
		ContactApps			NVARCHAR(2000),
		SiteURL				VARCHAR(100),
		MoreSiteURLs		VARCHAR(1000),
		NoSiteDesc			NVARCHAR(1000),
		DefaultCurrency		INT,
		TargetCountryCode	VARCHAR(5)
	)

	-- Capture current data before UPDATE (Old Data)
	INSERT INTO @OldDataTable (
		Phone,
		ContactApps,
		SiteURL,
		MoreSiteURLs,
		NoSiteDesc,
		DefaultCurrency,
		TargetCountryCode
	)
	SELECT ad.Phone,
		   ad.ContactApps,
		   ad.SiteURL,
		   ad.MoreSiteURLs,
		   ad.NoSiteDesc,
		   ai.DefaultCurrency,
		   ad.TargetCountryCode
	FROM dbo.AffInfo ai WITH (NOLOCK)
	LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId;

	-- Capture new data from parameters (New Data)
	INSERT INTO @NewDataTable (
		Phone,
		ContactApps,
		SiteURL,
		MoreSiteURLs,
		NoSiteDesc,
		DefaultCurrency,
		TargetCountryCode
	)
	SELECT @Phone,
		   @ContactApps,
		   @SiteURL,
		   @MoreSiteURLs,
		   @NoSiteDesc,
		   @DefaultBaseCurrency,
		   @TargetCountryCode;

	BEGIN TRY
		-- Update AffInfo table
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET DefaultCurrency = @DefaultBaseCurrency
		WHERE AffId = @AffId

		-- Update AffDetail table
		UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
		SET Phone				= ISNULL(@Phone, Phone),
			ContactApps			= ISNULL(@ContactApps, ContactApps),
			SiteURL				= ISNULL(@SiteURL, SiteURL),
			MoreSiteURLs		= ISNULL(@MoreSiteURLs, MoreSiteURLs),
			NoSiteDesc			= ISNULL(@NoSiteDesc, NoSiteDesc),
			TargetCountryCode	= ISNULL(@TargetCountryCode, TargetCountryCode)
		WHERE AffID = @AffId
	END TRY
	BEGIN CATCH
		-- Rollback manually using old data from @OldDataTable
		UPDATE ai WITH (ROWLOCK, UPDLOCK)
		SET DefaultCurrency = od.DefaultCurrency
		FROM dbo.AffInfo ai
			CROSS JOIN @OldDataTable od
		WHERE ai.AffId = @AffId

		UPDATE ad WITH (ROWLOCK, UPDLOCK)
		SET Phone = od.Phone,
			ContactApps = od.ContactApps,
			SiteURL = od.SiteURL,
			MoreSiteURLs = od.MoreSiteURLs,
			NoSiteDesc = od.NoSiteDesc,
			TargetCountryCode = od.TargetCountryCode
		FROM dbo.AffDetail ad
			CROSS JOIN @OldDataTable od
		WHERE ad.AffId = @AffId

		-- After rollback, refresh @NewDataTable from actual table data
		DELETE FROM @NewDataTable;
		INSERT INTO @NewDataTable (
			Phone,
			ContactApps,
			SiteURL,
			MoreSiteURLs,
			NoSiteDesc,
			DefaultCurrency,
			TargetCountryCode
		)
		SELECT ad.Phone,
			   ad.ContactApps,
			   ad.SiteURL,
			   ad.MoreSiteURLs,
			   ad.NoSiteDesc,
			   ai.DefaultCurrency,
			   ad.TargetCountryCode
		FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		WHERE ai.AffId = @AffId;

		-- Update process is unsuccessful. Please try again!
		SELECT @ErrCode = 1006, @ErrMsg = dbo.Aff_f_GetMessageById(303, @Language)
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	-- Build log strings from separate Old and New data tables
	SELECT @OldData =
		'Phone=' + ISNULL(Phone, '') + ',' +
		'ContactApps=' + ISNULL(ContactApps, '') + ',' +
		'SiteURL=' + ISNULL(SiteURL, '') + ',' +
		'MoreSiteURLs=' + ISNULL(MoreSiteURLs, '') + ',' +
		'NoSiteDesc=' + ISNULL(NoSiteDesc, '') + ',' +
		'DefaultCurrency=' + ISNULL(CONVERT(VARCHAR(10), DefaultCurrency), '')+ ',' +
		'TargetCountryCode=' + ISNULL(TargetCountryCode, '')
	FROM @OldDataTable

	SELECT @NewData =
		'Phone=' + ISNULL(Phone, '') + ',' +
		'ContactApps=' + ISNULL(ContactApps, '') + ',' +
		'SiteURL=' + ISNULL(SiteURL, '') + ',' +
		'MoreSiteURLs=' + ISNULL(MoreSiteURLs, '') + ',' +
		'NoSiteDesc=' + ISNULL(NoSiteDesc, '') + ',' +
		'DefaultCurrency=' + ISNULL(CONVERT(VARCHAR(10), DefaultCurrency), '')+ ',' +
		'TargetCountryCode=' + ISNULL(TargetCountryCode, '')
	FROM @NewDataTable
	
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