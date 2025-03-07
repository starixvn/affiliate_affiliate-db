/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaLink_CheckExistedTracking]
	@AffId					INT
	,@ChannelCode			VARCHAR(50) = ''
	,@LanguageCode			VARCHAR(10) = 'en-US'
	,@AffMediaLink			VARCHAR(500)
	,@AffDomain				NVARCHAR(50) = ''
    ,@IsOn					BIT = 0
	,@IsExistedTracking		BIT = 0 OUTPUT
	,@IsValidDomain			BIT = 0 OUTPUT
    
AS

/*
	Created: 20250226@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20250226@Sally: Initialize SP [RedmineID: #212201]
		- 20250305@Sally: Specific AFF Link SP [RedmineID: #219049]
        - 20250307@Sally: Enhance validate AffmediaLink  [RedmineID: #219049]

*/

BEGIN
	SET NOCOUNT ON
	DECLARE @AffDomainId 	INT
		,@PreferredLanguage VARCHAR(11)
        ,@AffMediaLink_http  VARCHAR(500)  = NULL
        ,@AffMediaLink_https VARCHAR(500)  = NULL
        ,@affMediaLinkId INT               = NULL

	SET @ChannelCode = ISNULL(@ChannelCode,'')
    SET @AffMediaLink_https = CONCAT ('https://',@AffMediaLink) -- Get https default for AffMediaLink
    SET @AffMediaLink_http  = CONCAT ('http://',@AffMediaLink) 

	SELECT @PreferredLanguage = ad.PreferredLanguage
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId 

	SELECT @IsExistedTracking = 0
	SELECT @IsValidDomain = 0

    -- Get AffMediaLinkId: only tracking link is ON
	SELECT @affMediaLinkId = AffMediaLinkId
	FROM dbo.AffMediaLink WITH (NOLOCK)
	WHERE AffId 		 = @AffId
		AND ChannelCode  = @ChannelCode
		AND LanguageCode = @LanguageCode
		AND AffMediaLink = @AffMediaLink_https
		AND IsShow 		 = 1

    IF(@affMediaLinkId = '')
    BEGIN
        SELECT @affMediaLinkId = AffMediaLinkId
        FROM dbo.AffMediaLink WITH (NOLOCK)
        WHERE AffId 		 = @AffId
            AND ChannelCode  = @ChannelCode
            AND LanguageCode = @LanguageCode
            AND AffMediaLink = @AffMediaLink_http
            AND IsShow 		 = 1
    END

	IF @affMediaLinkId IS NOT NULL
		SET @IsExistedTracking = 1	
	
	SELECT @AffDomainId	= DomainID
	FROM dbo.AffDomain WITH (NOLOCK)
	WHERE DomainName = @AffDomain 
		AND IsDeleted = 0

	IF EXISTS (
		SELECT 1 
		FROM dbo.DomainControl a WITH (NOLOCK)
				INNER JOIN dbo.LicenseeDomain b WITH (NOLOCK) ON a.LicenseeDomainId = b.DomainId
		WHERE a.MarketId 		= @PreferredLanguage
			AND a.AffDomainId 	= @AffDomainId
			AND a.[Status] 		= 1
			AND a.IsDeleted		= 0
			AND b.IsDeleted 	= 0			
		)
		SELECT @IsValidDomain = 1	

END
GO

