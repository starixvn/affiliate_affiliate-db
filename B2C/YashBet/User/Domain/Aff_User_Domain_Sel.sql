/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Domain_Sel]
	@AffID INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: List aff domain

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
	FROM dbo.AffDomain a WITH (NOLOCK)
		INNER JOIN dbo.DomainControl b WITH (NOLOCK) ON a.DomainID = b.AffDomainId
		INNER JOIN dbo.LicenseeDomain ld WITH (NOLOCK) ON b.LicenseeDomainId = ld.DomainId
		INNER JOIN dbo.AffDetail d WITH (NOLOCK) ON b.MarketID = d.PreferredLanguage
	WHERE b.STATUS = 1
		AND d.AffID = @AffID
		AND a.IsDeleted = 0
		AND b.IsDeleted = 0
		AND ld.IsDeleted = 0
	GROUP BY a.DomainID, a.DomainName, CONVERT(BIT, ISNULL(a.IsSSL, 0))
	ORDER BY a.DomainName
END
GO