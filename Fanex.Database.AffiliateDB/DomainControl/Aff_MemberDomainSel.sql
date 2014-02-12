ALTER PROCEDURE [dbo].[Aff_MemberDomainSel]
	
AS
	Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
	From [MemberDomain] a with(nolock)
		inner join AdminUser b with (nolock) on a.Creator = b.CustId
	order by a.DomainName

GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDomainSel] TO [vnteam]