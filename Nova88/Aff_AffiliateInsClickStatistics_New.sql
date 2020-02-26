/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics_New] 
	@AffiliateID INT
	,@AffDomain NVARCHAR(256) = ''
	,@PageCode VARCHAR(50) = 'sportsbook'
	,@LanguageCode VARCHAR(6) = 'en'
	,@IP VARCHAR(20) = ''
	,@Browser NVARCHAR(50) = ''
	,@URLReferrer NVARCHAR(300) = NULL
	,@DomainReferrer NVARCHAR(300) = NULL
	,@OS NVARCHAR(50) = ''
	,@Device NVARCHAR(50) = ''
	,@BrowserVersion NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage NVARCHAR(8) = ''
	,@UserAgent NVARCHAR(256) = ''
	,@Country NVARCHAR(256) = ''
	,@DeviceType TINYINT = 0
	,@RedirectPage NVARCHAR(256) = NULL OUTPUT
	,@ClickID BIGINT = 0 OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20111005@Johnny  
Task : record clicking Banner action with a specific tracking code  
DB: DBAFFN8G-Affiliate_N8G
Original:  
  
Revisions:  
	- 20111228: Get RedirectURL follow affiliate
	- 20121120: Redirect to the main domain (except list affiliates with pagecode 12betcasino still redirect to 12betcasino.com)
	- 20140220@Peter : Support EU aff link
	- 20140326@Bobby : check IsCLosed affiliate user
	- 20140708@Bobby : Apply DeviceType info
	- 20141013@Bobby : Hot fix Euro (PC-Mobile) site
	- 20150728@Bobby : Update new formation of mobile link
	- 20160624@Bobby : #59652 - Update new formation of mobile link
	- 20161215@Bobby : #68815 - Update new link formation for promotion page
	- 20180420@Percy : Change indiancricket to cricket when insert data [RedmineID: #92544]
	- 20180504@Walter: Exclude query by DeviceType [#94324]
	 
Param's Explanation:   
	- @DeviceType: 0-PC & 1-Mobile
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @AffUsername NVARCHAR(30)
		,@PreferredLanguage VARCHAR(11)
		,@Default12Betdomain NVARCHAR(100)
		,@IsCasino BIT
		,@AffType INT
		,@IsClosed BIT
		,@DomainDeviceType TINYINT = 0
		,@DomainName NVARCHAR(100)
		,@W3Http VARCHAR(5) = ''

	--Off default domain
	--SELECT @Default12Betdomain = NULL --If redirect page is null => redirect to this default domain

	SELECT @AffUsername = ai.Username
		,@PreferredLanguage = PreferredLanguage
		,@AffType = ai.AffType
		,@IsClosed = ai.IsClosed
	FROM AffDetail ad WITH (NOLOCK)
		INNER JOIN AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffiliateID
		AND STATUS = 'Approved'

	--check Affiliate ID  
	IF (
			@AffUsername IS NULL
			OR (
				@IsClosed = 1
				AND @AffUsername = '12BETAFF9151'
				)
			)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg = 'This affiliate does not exists. Please contact administrator!'

		RETURN
	END

	--Checking Input member IP
	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg = 'The IP is required. Please check!'

		RETURN
	END

	--Get redirect link
	BEGIN
		DECLARE @AffDomainId 	INT
			,@AffDomainName 	NVARCHAR(255)
			
		
		SELECT @AffDomainId = DomainID
			,@AffDomainName = DomainName
		FROM AffDomain WITH(NOLOCK)
		WHERE DomainName = @AffDomain
			AND IsDeleted = 0

		SELECT TOP 1 @DomainName = b.DomainName
			,@W3Http = CASE WHEN ISNULL(b.IsSSL, 0) = 1 THEN 'https' ELSE 'http' END
		FROM DomainControl a WITH (NOLOCK)
			INNER JOIN LicenseeDomain b WITH (NOLOCK) 
			ON a.LicenseeDomainId = b.DomainId
		WHERE a.MarketId = @PreferredLanguage
			AND a.AffDomainId = @AffDomainId
			AND a.[status] = 1
			AND a.IsDeleted = 0
			AND b.IsDeleted = 0

		--Replace Aff Domain by 12bet domain to redirect to 12bet site
		SET @RedirectPage = CASE 
				WHEN @DomainName IS NOT NULL THEN @W3Http + '://' + @DomainName + '/' + CAST(@AffiliateID AS VARCHAR(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx?type={typeid}'
				ELSE @Default12Betdomain
				END
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 103
			,@ErrMsg = 'This link does not exists. Please contact administrator!'
		RETURN
	END
	ELSE
	BEGIN
		DECLARE @EUDomain 		VARCHAR(100)		
		SELECT @EUDomain 		= 'eu.12bet.com'
		
		--final check for EU member site
		IF(@LanguageCode IN ('eneuro', 'es'))
		BEGIN
			-- Reset language code
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'eneuro', 'en')
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'es', 'en')
			-- Reset mobile link
			IF(@DomainName <> @EUDomain)
			BEGIN
				SET @RedirectPage = REPLACE(@RedirectPage, @DomainName, @EUDomain)
			END
		END
		IF(@PageCode IN ('promotion') AND @LanguageCode IN ('hien'))
		BEGIN
			SELECT @RedirectPage = REPLACE(@RedirectPage, 'hien', 'hi')
		END
	END
	
	-- process aff link
	DECLARE @CountryCode VARCHAR(5)
		,@IPNum BIGINT

	SELECT @IPNum = [dbo].[Aff_IPConvertToNumber](@IP)

	SET @CountryCode = (
			SELECT TOP (1) Code3
			FROM IPv4Addresses(NOLOCK)
			WHERE @IPNum BETWEEN [From]
					AND [To]
			)

	INSERT INTO [ClickStatistics] (
		[AffID]
		,[UpdatedTime]
		,[IP]
		,[Date]
		,[Browser]
		,[URLReferrer]
		,[DomainReferrer]
		,[OS]
		,[Device]
		,[BrowserVersion]
		,[BrowserResolution]
		,[BrowserLanguage]
		,[UserAgent]
		,[Country]
		,[LanguageCode]
		,[SportCode]
		,[RedirectURL]
		,[Status]
		,[DeviceType]
		)
	VALUES (
		@AffiliateID
		,getdate()
		,@IP
		,CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
		,@Browser
		,coalesce(@URLReferrer, 'none')
		,coalesce(@DomainReferrer, 'none')
		,@OS
		,@Device
		,@BrowserVersion
		,@BrowserResolution
		,@BrowserLanguage
		,@UserAgent
		,coalesce(@CountryCode, '(not set)', @Country)
		,(CASE 
			WHEN @LanguageCode = 'vi' THEN 'vn'
			ELSE @LanguageCode END
			) --Only store vn for vietnamese
		,CASE WHEN @PageCode = 'indiancricket' THEN 'cricket' ELSE @PageCode END
		,@RedirectPage --if not Casino aff => redirect to main domain
		,0
		,@DeviceType
		)

	SELECT @ClickID = SCOPE_IDENTITY()

	SELECT @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)

	SELECT @RedirectPage = replace(@RedirectPage, '{typeid}', @AffType)

	UPDATE [ClickStatistics] WITH (ROWLOCK, UPDLOCK)
	SET [RedirectURL] = @RedirectPage
	WHERE clickId = @ClickID

	RETURN
END
GO