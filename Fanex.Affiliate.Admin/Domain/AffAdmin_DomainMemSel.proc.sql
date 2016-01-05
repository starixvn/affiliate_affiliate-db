ALTER PROCEDURE [dbo].[AffAdmin_DomainMemSel]
	@LicenseeID INT
/*
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/	
AS
	Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
	From [MemberDomain] a with(nolock)
		inner join dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) b on a.Creator = b.UserID
	order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_DomainMemSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DomainMemSel] TO [vnteam] AS [dbo]