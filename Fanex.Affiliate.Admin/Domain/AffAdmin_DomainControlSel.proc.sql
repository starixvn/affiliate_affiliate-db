ALTER PROCEDURE [dbo].[AffAdmin_DomainControlSel]  
	@CountryID nvarchar(10) = null  
AS  
/*  
Created: 20130903@Johnny.Trinh  
Task : Select Domain Control  
DB: DB052.Affiliate_12BET  
Revision:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Alex  : Support Liecnsee admin portal #90545
*/  
  
select a.ID,  
	d.CountryId,  
	d.CountryName,  
	b.DomainId as AffDomainId,  
	b.DomainName as AffDomain,  
	c.DomainId as MemberDomainId,  
	c.DomainName as MemberDomain,  
	a.CreateDate,  
	a.CreatorName as Creator,  
	a.[Status]  
from AffDomainControl a with (nolock)  
	inner join AffDomain b with (nolock) on a.AffDomainId = b.DomainId  
	inner join MemberDomain c with (nolock) on a.MemberDomainID = c.DomainID  
	inner join Country d with (nolock) on a.CountryID = d.CountryID  
	
where ISNULL(@CountryID, a.CountryID) = a.CountryID  
order by a.[Status] desc, b.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainControlSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainControlSel] TO [vnteam] AS [dbo]