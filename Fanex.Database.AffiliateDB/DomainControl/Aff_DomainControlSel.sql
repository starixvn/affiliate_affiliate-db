ALTER PROCEDURE [dbo].[Aff_DomainControlSel]
	@CountryID nvarchar(10) = null
AS
/*
Created: 20121115@Johnny.Trinh
Task : Select Domain Control
DB: DB052.Affiliate_12BET
*/

select a.Id,
	d.CountryID,
	d.CountryName,
	b.DomainId as AffDomainId,
	b.DomainName as AffDomain,
	c.DomainId as RedirectDomainId,
	c.DomainName as RedirectDomain,
	a.CreateDate,
	e.Username as Creator,
	a.[Status]
from AffDomainControl a with (nolock)
	inner join AffDomain b with (nolock) on a.AffDomainId = b.DomainId
	inner join MemberDomain c with (nolock) on a.MemberDomainID = c.DomainID
	inner join Country d with (nolock) on a.CountryID = d.CountryID
	inner join AdminUser e with (nolock) on a.Creator = e.CustId
where ISNULL(@CountryID, a.CountryID) = a.CountryID
order by a.[Status] desc, b.DomainName


GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlSel] TO [vnteam]