/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatistics_BulkCache]
AS
/*
	Created: 20250725@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Cache data

	Revisions:  
		- 20250725@Lewis: Initialize SP [RedmineID: #233088]
*/
BEGIN
    SET NOCOUNT ON;

    -- Priority 1: Specific domain control
    SELECT DISTINCT
        ai.AffCode,
        sdc.AffDomainName AS AffDomain,
        sdc.LicenseeDomainName AS RedirectDomain,
		sdc.LicenseeDomainIsSSL AS IsSSL
    FROM dbo.SpecificDomainControl sdc WITH (NOLOCK)
    INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
        ON sdc.AffId = ai.AffId
        AND ai.Status = 'Approved'
        AND (ai.IsClosed IS NULL OR ai.IsClosed = 0)
        AND sdc.Status = 1
	ORDER BY 
        AffCode, 
        AffDomainName

    -- Priority 2: Normal domain control
    SELECT DISTINCT
        ad.DomainName AS AffDomain,
        tc.ShortedCode AS LanguageCode,
        m.ShortedCode AS LanguageLink,
        ld.DomainName AS RedirectDomain,
		ld.IsSSL AS IsSSL
    FROM dbo.DomainControl dc WITH (NOLOCK)
    INNER JOIN dbo.LicenseeDomain ld WITH (NOLOCK)
        ON ld.DomainId = dc.LicenseeDomainId
        AND ld.IsDeleted = 0
    INNER JOIN Affdomain ad WITH (NOLOCK)
        ON ad.DomainId = dc.AffDomainId
		AND ad.IsDeleted = 0
    INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) 
        ON tc.CountryCode = dc.TargetCountryCode
    INNER JOIN dbo.Market m WITH (NOLOCK) 
        ON tc.MarketID = m.MarketId
        AND m.IsDeleted = 0
    WHERE dc.Status = 1 AND dc.IsDeleted = 0
    ORDER BY 
        AffDomain, 
        LanguageCode;

	SELECT tc.ShortedCode AS LanguageCode,
        m.ShortedCode AS LanguageLink
	FROM dbo.TargetCountry tc WITH (NOLOCK) 
    INNER JOIN dbo.Market m WITH (NOLOCK) 
        ON tc.MarketID = m.MarketId
        AND m.IsDeleted = 0

	SELECT ai.AffCode, cg.Groupname, ad.TargetCountryCode
    FROM dbo.AffInfo ai WITH (NOLOCK)
	INNER JOIN dbo.AffDetail ad WITH (NOLOCK)
		ON ai.AffId = ad.AffId
    INNER JOIN dbo.CommGroup cg WITH (NOLOCK)
        ON cg.GroupId = ai.GroupId
        AND cg.IsDeleted = 0
    WHERE ai.Status = 'Approved'
    AND ai.IsClosed IS NULL OR ai.IsClosed = 0;

END
GO

