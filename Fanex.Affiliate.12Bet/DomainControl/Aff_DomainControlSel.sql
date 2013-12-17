ALTER PROCEDURE [dbo].[Aff_DomainControlSel]
	@MarketId nvarchar(10) = null
AS
/*
Created: 20121115@Johnny.Trinh
Task : Select Domain Control
DB: DB052.Affiliate_12BET
*/

select a.Id,
	d.MarketId,
	d.MarketName,
	b.DomainId as AffDomainId,
	b.DomainName as AffDomain,
	c.DomainId as RedirectDomainId,
	c.DomainName as RedirectDomain,
	a.CreateDate,
	e.Username as Creator,
	a.[Status]
from AffDomainControl a with (nolock)
	inner join AffDomain b with (nolock) on a.AffDomainId = b.DomainId
	inner join [12BetDomain] c with (nolock) on a.[12BetDomainId] = c.DomainId
	inner join Market d with (nolock) on a.MarketId = d.MarketId
	inner join Affiliate_User e with (nolock) on a.Creator = e.CustId
where ISNULL(@MarketId, a.MarketID) = a.MarketID
order by a.[Status] desc, b.DomainName


GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlSel] TO [vnteam]