ALTER PROCEDURE [dbo].[Aff_Domain12BetSel]
	
AS
	Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
	From [12BetDomain] a with(nolock)
		inner join Affiliate_User b with (nolock) on a.Creator = b.CustId
	order by a.DomainName

GO
GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_Domain12BetSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Domain12BetSel] TO [vnteam]