ALTER PROCEDURE [dbo].[AffAdmin_DomainMemSel]
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Alex  : Support Liecnsee admin portal #90545
*/	
AS
	Select a.DomainID, a.DomainName, a.CreatorName as Creator, a.CreateDate
	From [MemberDomain] a with(nolock)
		
	order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemSel] TO [vnteam] AS [dbo]