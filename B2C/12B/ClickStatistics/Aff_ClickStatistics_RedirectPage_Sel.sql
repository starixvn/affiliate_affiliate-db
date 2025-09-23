/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_ClickStatistics_RedirectPage_Sel
	@AffCode			VARCHAR(20)
	,@AffDomain			NVARCHAR(50) = ''
	,@PageCode			VARCHAR(50) = '' OUTPUT
	,@LanguageCode		VARCHAR(6) = 'en'
	,@RedirectPage		NVARCHAR(256) = NULL OUTPUT
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS
/*
    Created: 20250730@Lewis
    Task: Generate redirect page URL without click tracking – Get redirect URL for affiliate links without inserting click statistics
    DB: DBAFF12B-Affiliate_12B

    Revisions:
        - 20250730@Lewis: Generate redirect page URL without click tracking [RedmineID: #233088]
		- 20250808@Eddie: Add new condition [RedmineID: #233219]
        - 20250918@Sally: Get PageCode Active Status [RedmineID: #236797]
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
		  , @TargetCountryCode 	VARCHAR(5)
		  , @LanguageLink 		NVARCHAR(10)
		  , @DealId 			INT
		  , @DealName 			NVARCHAR(100)
		  , @IsMobile_LP 		BIT -- check for landing page
		  , @IsMobile_DC 		BIT -- check for domain control
		  , @IsMobile_SDC 		BIT -- check for specific domain control
		  , @Default_PageId 	SMALLINT
		  , @Default_PageCode	VARCHAR(50)
	
	-- Get Info
	BEGIN
		-- AffId
		SELECT @AffId = ac.AffId
		FROM dbo.AffiliateCode ac WITH (NOLOCK)
		WHERE ac.AffCode = @AffCode

		SELECT @AffUsername = ai.Username
		      ,@IsClosed = ai.IsClosed
			  ,@DealId = ai.GroupId
			  ,@DealName = cg.GroupName
		FROM dbo.AffDetail ad WITH (NOLOCK)
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
			INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = ai.GroupId
		WHERE ai.AffId = @AffId 
		  AND ai.Status = 'Approved'
		  AND cg.IsDeleted = 0

		-- TargetCountryCode, LanguageLink
		SELECT @TargetCountryCode = tc.CountryCode
			  ,@LanguageLink = m.ShortedCode
		FROM dbo.TargetCountry tc WITH (NOLOCK)
			INNER JOIN dbo.Market m WITH (NOLOCK) ON tc.MarketID = m.MarketId
		WHERE tc.ShortedCode = @LanguageCode;

		-- IsMobile_LP for checking
		SELECT @IsMobile_LP = IsMobile
		FROM dbo.LandingPage WITH (NOLOCK)
		WHERE IsDeleted = 0
            AND StatusId = 1  -- Active Status
		    AND PageCode = @PageCode

		-- Default pageid
		SELECT @Default_PageId = CONVERT(SMALLINT, SValue)
		FROM dbo.SystemSettings WITH (NOLOCK)
		WHERE SName = 'LandingPage'

		-- Pagecode default
		SELECT @Default_PageCode = PageCode
		FROM dbo.LandingPage WITH (NOLOCK)
		WHERE PageId = @Default_PageId

	END

	--Check Affiliate ID 
	IF @AffUsername IS NULL OR ISNULL(@IsClosed, 1) = 1
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'This affiliate does not exists. Please contact administrator!';
		RETURN;
	END

	-- Update @PageCode with specific cases
	BEGIN

		IF @IsMobile_LP IS NULL
		BEGIN
			SELECT @PageCode = @Default_PageCode
		END

		IF EXISTS (
			SELECT 1
			FROM dbo.LandingPage WITH (NOLOCK)
			WHERE IsDeleted = 0
                AND StatusId = 1  -- Active Status 
                AND PageCode = @PageCode
                AND (
                    IsExcluded = 1 AND ( ',' + DealIds + ',' LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) )
                    OR IsExcluded = 0 AND ( ',' + DealIds + ',' NOT LIKE ('%,' + CONVERT(VARCHAR(10), @DealId) + ',%' ) AND DealIds <> '0' )
                )
		)
		BEGIN
			SELECT @PageCode = @Default_PageCode
		END
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
				  ,@IsSSL = LicenseeDomainIsSSL
				  ,@IsMobile_SDC = IsMobile
			FROM dbo.SpecificDomainControl WITH (NOLOCK)
			WHERE AffDomainName = @AffDomain
			  AND AffId = @AffId
			  AND Status = 1

			IF ( @IsMobile_LP <> @IsMobile_SDC )
			BEGIN
				SELECT @PageCode = @Default_PageCode
			END
		END
		ELSE
		BEGIN
			--Normal Domain
			SELECT @AffDomainId	= DomainID
			FROM dbo.AffDomain WITH (NOLOCK)
			WHERE DomainName = @AffDomain 
			  AND IsDeleted = 0
		
			SELECT TOP(1) @LicenseeDomain = b.DomainName
					     ,@IsSSL = b.IsSSL
					     ,@IsMobile_DC = a.IsMobile
			FROM dbo.DomainControl a WITH (NOLOCK)
				INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
			WHERE a.TargetCountryCode = @TargetCountryCode
			  AND a.AffDomainId = @AffDomainId
			  AND a.[Status] = 1
			  AND a.IsDeleted = 0
			  AND b.IsDeleted = 0

			IF ( @IsMobile_LP <> @IsMobile_DC )
			BEGIN
				SELECT @PageCode = @Default_PageCode
			END

		END

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