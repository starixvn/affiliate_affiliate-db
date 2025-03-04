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

*/

BEGIN
	SET NOCOUNT ON
	DECLARE @AffDomainId 	INT
		,@PreferredLanguage VARCHAR(11)

	SET @ChannelCode = ISNULL(@ChannelCode,'')

	SELECT @PreferredLanguage = ad.PreferredLanguage
	FROM dbo.AffDetail ad WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ad.AffId
	WHERE ai.AffId = @AffId 

	SELECT @IsExistedTracking = 0
	SELECT @IsValidDomain = 0


	IF EXISTS (
		SELECT 1 
		FROM dbo.AffMediaLink WITH (NOLOCK) 
		WHERE AffId = @AffId 
			AND ChannelCode  = @ChannelCode
			AND LanguageCode = @LanguageCode 
			AND AffMediaLink = @AffMediaLink
            AND IsShow       = @IsOn
		)
		SELECT @IsExistedTracking = 1	
	
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

