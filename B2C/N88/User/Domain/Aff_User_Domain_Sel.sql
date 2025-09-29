/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Domain_Sel]
	@AffID INT
	,@TargetCountryCode	VARCHAR(5) = ''
AS

/*
	Created: 20191210@Percy
	Task: List aff domain
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121973]
		- 20250729@Danny: Add TargetCountry [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.DomainControl b WITH (NOLOCK) ON a.DomainID = b.AffDomainId
		INNER JOIN dbo.LicenseeDomain ld WITH (NOLOCK) ON b.LicenseeDomainId = ld.DomainId
		--INNER JOIN dbo.AffDetail d WITH (NOLOCK) ON b.TargetCountryCode = d.TargetCountryCode
	WHERE b.STATUS = 1
		--AND d.AffID = @AffID
		AND a.IsDeleted = 0
		AND b.IsDeleted = 0
		AND ld.IsDeleted = 0
		AND b.TargetCountryCode = @TargetCountryCode
	GROUP BY a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0))
	ORDER BY a.DomainName
END
GO