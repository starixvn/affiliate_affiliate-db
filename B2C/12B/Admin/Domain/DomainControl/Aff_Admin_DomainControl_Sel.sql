/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_DomainControl_Sel]
	@DomainControlId	INT = 0
	,@TargetCountryCode	VARCHAR(5) = ''
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Domain Control - Select

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250417@Lewis: Add BlockTargetCountry [RedmineID: #223644]
		- 20250721@Eddie: Add Device and Deal Name [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON

	IF @DomainControlId <> 0
	BEGIN
		SELECT
			a.Id AS DomainControlId
			,d.CountryCode AS TargetCountryCode
			,d.CountryName AS TargetCountryName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
			,a.IsMobile
			,a.IsExcluded
			,a.DealIds
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.LicenseeDomain c WITH (NOLOCK) ON a.LicenseeDomainId = c.DomainId
			INNER JOIN TargetCountry d WITH (NOLOCK) ON a.MarketId = d.MarketId AND a.TargetCountryCode = d.CountryCode
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE a.Id = @DomainControlId
		  AND a.IsDeleted = 0
	END
	ELSE
	BEGIN
		SELECT
			a.Id AS DomainControlId
			,d.CountryCode AS TargetCountryCode
			,d.CountryName AS TargetCountryName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
			,a.IsMobile
			,a.IsExcluded
			,a.DealIds
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.LicenseeDomain c WITH (NOLOCK) ON a.LicenseeDomainId = c.DomainId
			INNER JOIN TargetCountry d WITH (NOLOCK) ON a.MarketId = d.MarketId AND a.TargetCountryCode = d.CountryCode
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE (ISNULL(@TargetCountryCode, '') = '' OR a.TargetCountryCode = @TargetCountryCode)
			AND a.IsDeleted = 0
		ORDER BY a.CreateDate DESC
			    ,d.CountryName
			    ,b.DomainName
	END
END
GO