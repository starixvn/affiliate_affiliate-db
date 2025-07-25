/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_ClickStatistics_RedirectPage_Sel
	@AffCode			VARCHAR(20)
	,@AffDomain			NVARCHAR(50) = ''
	,@PageCode			VARCHAR(50) = ''
	,@LanguageCode		VARCHAR(6) = 'en'
	,@RedirectPage		NVARCHAR(256) = NULL OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS
/*
        Created:      20250730@Lewis
        Task:         Generate redirect page URL without click tracking – Get redirect URL for affiliate links without inserting click statistics
        DB:           DBAFF12B-Affiliate_12B
        Revisions:
            - 20250730@Lewis: Generate redirect page URL without click tracking [RedmineID: #233088]
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @AffId 				INT = NULL
	      , @AffUsername 		NVARCHAR(30)
		  , @IsClosed			BIT
		  , @LicenseeDomain		NVARCHAR(50)
		  , @IsSSL				BIT
		  , @AffDomainId 		INT
		  , @RedirectDomain		NVARCHAR(256) = NULL
		  , @LanguageMediaLink	VARCHAR(11)	  = '';

	--Get AffId
	SELECT @AffId = ac.AffId
	FROM dbo.AffiliateCode ac WITH (NOLOCK)
	WHERE ac.AffCode = @AffCode;
		
	--Get TargetCountryCode
	DECLARE @TargetCountryCode VARCHAR(5);
	SELECT @TargetCountryCode = tc.CountryCode
			,@LanguageMediaLink = tc.MarketId
	FROM dbo.TargetCountry tc WITH (NOLOCK)
	WHERE tc.ShortedCode = @LanguageCode;

	SELECT @AffUsername = ai.Username
		 , @IsClosed = ai.IsClosed
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId 
		AND ai.Status = 'Approved';

	--check Affiliate ID 
	IF @AffUsername IS NULL OR @IsClosed IS NULL OR @IsClosed = 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!';
		RETURN;
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
				AND Status = 1;
		END
		ELSE
		BEGIN
			--Normal Domain
			SELECT @AffDomainId	= DomainID
			FROM dbo.AffDomain WITH (NOLOCK)
			WHERE DomainName = @AffDomain 
				AND IsDeleted = 0;
		
			SELECT TOP (1) @LicenseeDomain 	= b.DomainName
					,  @IsSSL		   		= b.IsSSL
			FROM dbo.DomainControl a WITH (NOLOCK)
				INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
			WHERE a.TargetCountryCode = @TargetCountryCode
				AND a.AffDomainId = @AffDomainId
				AND a.[Status] = 1
				AND a.IsDeleted = 0
				AND b.IsDeleted = 0;
		END
		
		DECLARE @LanguageLink VARCHAR(10);

		SELECT @LanguageLink = m.ShortedCode
		FROM dbo.TargetCountry tc WITH (NOLOCK)
		INNER JOIN dbo.Market m WITH (NOLOCK) ON tc.MarketID = m.MarketId
		WHERE tc.ShortedCode = @LanguageCode;

		IF @RedirectDomain IS NOT NULL
		BEGIN	
			--Specific redirect domain	
			SET @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @RedirectDomain + '/' + @LanguageLink + '/' + @PageCode + '?affCode=' + @AffCode;
		END
		ELSE
		BEGIN
		-- Replace Affilliate domain by Licensee domain to redirect to licensee site
			SELECT @RedirectPage = CASE WHEN @IsSSL = 1 THEN 'https' ELSE 'http' END + '://' + @LicenseeDomain + '/' + @LanguageLink + '/' + @PageCode + '?affCode=' + @AffCode;
		END
	END

	IF (@RedirectPage IS NULL)
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'This link does not exists. Please contact administrator!';
		RETURN;
	END

END;
GO
