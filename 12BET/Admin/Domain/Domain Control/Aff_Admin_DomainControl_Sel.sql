/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_DomainControl_Sel]
	@DomainControlId	INT = 0
	,@MarketId			NVARCHAR(10) = ''
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Domain Control - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	IF @DomainControlId <> 0
		SELECT
			a.Id AS DomainControlId
			,d.MarketName
			,b.DomainName	AS AffDomain
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.AffDomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON a.[12BetDomainId] = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE a.Id = @DomainControlId
			AND a.IsDeleted = 0
	ELSE
		SELECT
			a.Id AS DomainControlId
			,d.MarketName
			,b.DomainName	AS AffDomain
			,c.DomainName	AS RedirectDomain
			,e.Username		AS Creator
			,a.CreateDate	AS CreatedDate
			,a.Status
		FROM dbo.AffDomainControl a WITH (NOLOCK)
			INNER JOIN dbo.AffDomain b WITH (NOLOCK) ON a.AffDomainId = b.DomainId
			INNER JOIN dbo.[12BetDomain] c WITH (NOLOCK) ON a.[12BetDomainId] = c.DomainId
			INNER JOIN Market d WITH (NOLOCK) ON a.MarketId = d.MarketId
			INNER JOIN Affiliate_User e WITH (NOLOCK) ON a.Creator = e.CustId
		WHERE (ISNULL(@MarketId, '') = '' OR a.MarketID = @MarketId)
			AND a.IsDeleted = 0
		ORDER BY
			d.MarketName
			,b.DomainName
END
GO