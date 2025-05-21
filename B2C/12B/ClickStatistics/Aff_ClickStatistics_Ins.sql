/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatistics_Ins]
	@AffCode			VARCHAR(20)
	,@AffDomain			NVARCHAR(50) = ''
	,@PageCode			VARCHAR(50) = ''
	,@LanguageCode		VARCHAR(6) = 'en'
	,@IP				VARCHAR(50) = ''
	,@Browser			NVARCHAR(50) = ''
	,@URLReferrer		NVARCHAR(300) = NULL
	,@DomainReferrer	NVARCHAR(300) = NULL
	,@AffMediaLink		VARCHAR(500) = NULL
	,@OS				NVARCHAR(50) = ''
	,@Device			NVARCHAR(50) = ''
	,@BrowserVersion	NVARCHAR(16) = ''
	,@BrowserResolution NVARCHAR(16) = ''
	,@BrowserLanguage	NVARCHAR(8) = ''
	,@UserAgent			NVARCHAR(256) = ''
	,@Country			NVARCHAR(256) = ''
	,@DeviceType		TINYINT = 0
    ,@ChannelCode       VARCHAR(50) = NULL
	,@RedirectPage		NVARCHAR(256) = NULL OUTPUT
	,@ClickID			BIGINT = 0 OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Clicking Banner action

	Revisions:  
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250221@Eddie: Support to config redirect link for specific affiliates [RedmineID: #218213]
		- 20250221@Sally: Enhance AFFMediaLink  [RedmineID: #212201]
		- 20250305@Sally: Specific AFF Link SP [RedmineID: #219049]
		- 20250305@Sally: Enhance validate AffmediaLink  [RedmineID: #219049]
		- 20250313@Sally: fix get affdomain  [RedmineID: #219984]
		- 20250320@Sophia: Add clickID into RedirectPage [Redmine: #219949]
		- 20250402@Lewis: User table SpecificDomainControl [Redmine: #221035]
		- 20250408@Sophia: Add ChannelCode into ClickStatistics [Redmine: #222765]
		- 20250417@Lewis: Add TargetCountry [RedmineID: #223644]
		- 20250515@Lewis: Get TargetCountryCode by table TargetCountry [RedmineID: #227338]
		- 20250521@Lewis: Get ShortedCode by table TargetCountry for Secondary Language  [RedmineID: #227338]
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @AffId 				INT = NULL
	      , @AffUsername 		NVARCHAR(30)
		  , @IsClosed			BIT
		  , @PreferredLanguage 	VARCHAR(11)
		  , @LicenseeDomain		NVARCHAR(50)
		  , @IsSSL				BIT
		  , @AffDomainId 		INT
		  , @RedirectDomain		NVARCHAR(256) = NULL
		  ,	@affMediaLinkId		VARCHAR(50)	  = ''
		  , @LanguageMediaLink	VARCHAR(11)	  = ''
          , @AffMediaLink_http  VARCHAR(500)  = NULL
          ,	@AffMediaLink_https	VARCHAR(500)  = NULL
    
    SET @AffMediaLink_https = CONCAT ('https://',@AffMediaLink) -- Get https default for AffMediaLink
    SET @AffMediaLink_http  = CONCAT ('http://',@AffMediaLink) 

    SET @ChannelCode = ISNULL(@ChannelCode, '')

	--Get AffId
	SELECT @AffId = ac.AffId
	FROM dbo.AffiliateCode ac WITH(NOLOCK)
	WHERE ac.AffCode = @AffCode
		
	--Get TargetCountryCode
	DECLARE @TargetCountryCode VARCHAR(5)
	SELECT @TargetCountryCode = tc.CountryCode
			,@LanguageMediaLink = tc.MarketId
	FROM TargetCountry tc WITH (NOLOCK)
	WHERE tc.ShortedCode = @LanguageCode

	IF COALESCE(@IP, '') = ''
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The IP is required. Please check!'
		RETURN
	END

	SELECT @AffUsername = ai.Username
		 , @PreferredLanguage = ad.PreferredLanguage
		 , @IsClosed = ai.IsClosed
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId AND ai.Status = 'Approved'

	--check Affiliate ID 
	IF @AffUsername IS NULL OR @IsClosed IS NULL OR @IsClosed = 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!'
		RETURN
	END

	--Get redirect link
	BEGIN
		IF EXISTS(
			SELECT TOP 1 1
			FROM dbo.SpecificDomainControl WITH (NOLOCK)
			WHERE AffDomainName = @AffDomain
				AND AffId = @AffId
				AND Status = 1
		)
		BEGIN
			-- Get redirect domain of specific AFF
			SELECT @RedirectDomain = LicenseeDomainName
				, @IsSSL = LicenseeDomainIsSSL
			FROM dbo.SpecificDomainControl WITH (NOLOCK)
			WHERE AffDomainName = @AffDomain
				AND AffId = @AffId
				AND Status = 1
		END
		ELSE
		BEGIN
			--Normal Domain
			SELECT @AffDomainId	= DomainID
			FROM dbo.AffDomain WITH (NOLOCK)
			WHERE DomainName = @AffDomain 
				AND IsDeleted = 0
		
			SELECT TOP (1) @LicenseeDomain 	= b.DomainName
					,  @IsSSL		   		= b.IsSSL
			FROM dbo.DomainControl a WITH (NOLOCK)
				INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
			WHERE a.TargetCountryCode = @TargetCountryCode
				AND a.AffDomainId = @AffDomainId
				AND a.[Status] = 1
				AND a.IsDeleted = 0
				AND b.IsDeleted = 0
		END
		
		-- Get AffMediaLinkId: only tracking link is ON
		SELECT @affMediaLinkId = AffMediaLinkId
			,@AffMediaLink 	   = AffMediaLink
		FROM dbo.AffMediaLink WITH (NOLOCK)
		WHERE AffId 		 = @AffId
			AND ChannelCode  = @ChannelCode
			AND LanguageCode = @LanguageMediaLink
			AND AffMediaLink = @AffMediaLink_https
			AND IsShow 		 = 1

        IF(@affMediaLinkId = '')
        BEGIN
            SELECT @affMediaLinkId = AffMediaLinkId
				,@AffMediaLink     = AffMediaLink
            FROM dbo.AffMediaLink WITH (NOLOCK)
            WHERE AffId 		 = @AffId
                AND ChannelCode  = @ChannelCode
                AND LanguageCode = @LanguageMediaLink
                AND AffMediaLink = @AffMediaLink_http
                AND IsShow 		 = 1
        END
		
		DECLARE @LanguageLink VARCHAR(10)

		SELECT @LanguageLink = m.ShortedCode
		FROM TargetCountry tc WITH (NOLOCK)
		INNER JOIN Market m WITH (NOLOCK) ON tc.MarketID = m.MarketId
		WHERE tc.ShortedCode = @LanguageCode

		IF @RedirectDomain IS NOT NULL
		BEGIN	
			--Specific redirect domain	
			SET @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @RedirectDomain + '/' + @LanguageLink + '/' + @PageCode + '?affCode=' + @AffCode + '&affMediaLinkId=' + @affMediaLinkId
		END
		ELSE
		BEGIN
		-- Replace Affilliate domain by Licensee domain to redirect to licensee site
			SELECT @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @LicenseeDomain + '/' + @LanguageLink + '/' + @PageCode + '?affCode=' + @AffCode + '&affMediaLinkId=' + @affMediaLinkId
		END
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This link does not exists. Please contact administrator!'
		RETURN;
	END

	-- Insert into ClickStatistics
	BEGIN
		DECLARE @IPNum BIGINT, @CountryCode VARCHAR(256)
		SELECT  @IPNum = dbo.Aff_IPConvertToNumber(@IP)

		SELECT  TOP 1 @CountryCode =  Code3
		FROM dbo.IPv4Addresses WITH (NOLOCK)
		WHERE @IPNum BETWEEN [From] AND [To]

		INSERT INTO dbo.ClickStatistics
		(
			AffId
			,UpdatedTime
			,IP
			,Date
			,Browser
			,URLReferrer
			,DomainReferrer
			,AffMediaLink
			,OS
			,Device
			,BrowserVersion
			,BrowserResolution
			,BrowserLanguage
			,UserAgent
			,Country
			,LanguageCode
			,SportCode
			,RedirectURL
			,Status
			,DeviceType
			,ChannelCode
		)
		VALUES
		(
			@AffId
			,CURRENT_TIMESTAMP
			,@IP
			,CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)
			,@Browser
			,ISNULL(@URLReferrer, 'none')
			,ISNULL(@DomainReferrer, 'none')
			,ISNULL(@AffMediaLink, 'none')
			,@OS
			,@Device
			,@BrowserVersion
			,@BrowserResolution
			,@BrowserLanguage
			,@UserAgent
			,COALESCE(@CountryCode, '(not set)', @Country)
			,CASE WHEN @LanguageCode = 'vi' THEN 'vn' ELSE @LanguageCode END
			,@PageCode
			,@RedirectPage
			,0
			,@DeviceType
			,@ChannelCode
		)

		SELECT @ClickID = SCOPE_IDENTITY()
		
		SELECT @RedirectPage = @RedirectPage + '&clickId=' + CONVERT(VARCHAR(20), @clickId)
		
		UPDATE 	dbo.ClickStatistics WITH (ROWLOCK,UPDLOCK)
		SET 	RedirectURL = @RedirectPage
		WHERE 	ClickId = @ClickId
		
	END
END
GO