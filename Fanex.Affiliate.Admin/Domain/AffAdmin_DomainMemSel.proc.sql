CREATE PROCEDURE [dbo].[AffAdmin_DomainMemSel]
	
AS
	Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
	From [MemberDomain] a with(nolock)
		inner join AdminUser b with (nolock) on a.Creator = b.CustId
	order by a.DomainName

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemSel] TO [vnteam]