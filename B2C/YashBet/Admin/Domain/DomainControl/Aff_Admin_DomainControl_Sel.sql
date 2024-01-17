/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Sel]
	@DomainControlId	INT = 0
	,@MarketId			NVARCHAR(10) = ''
AS

/*  
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Domain - Domain Control - Select

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	IF @DomainControlId <> 0
		SELECT
			a.Id AS DomainControlId
			,a.MarketId
			,d.MarketName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.LicenseeDomain c WITH (NOLOCK) ON a.LicenseeDomainId = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE a.Id = @DomainControlId
			AND a.IsDeleted = 0
	ELSE
		SELECT
			a.Id AS DomainControlId
			,a.MarketId
			,d.MarketName
			,b.DomainId		AS AffDomainId
			,b.DomainName	AS AffDomain
			,c.DomainId		AS RedirectDomainId
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.DomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.LicenseeDomain c WITH (NOLOCK) ON a.LicenseeDomainId = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE (ISNULL(@MarketId, '') = '' OR a.MarketID = @MarketId)
			AND a.IsDeleted = 0
		ORDER BY
			d.MarketName
			,b.DomainName
END
GO