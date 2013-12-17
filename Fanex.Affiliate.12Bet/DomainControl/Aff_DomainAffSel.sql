ALTER PROCEDURE [dbo].[Aff_DomainAffSel]
	
AS
	Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
	From AffDomain a with(nolock)
		inner join Affiliate_User b with (nolock) on a.Creator = b.CustId
	order by a.DomainName
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffSel] TO [vnteam]