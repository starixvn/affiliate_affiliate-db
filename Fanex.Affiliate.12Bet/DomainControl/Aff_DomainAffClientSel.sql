ALTER PROCEDURE [dbo].[Aff_DomainAffClientSel]
	@AffID int 
AS
	Select a.DomainID, a.DomainName
	From AffDomain a with(nolock)
	inner join AffDomainControl b with(nolock) on a.DomainID = b.AffDomainID	
	inner join AffDetail d with(nolock) on b.MarketID = d.PreferredLanguage 
	where b.Status = 1 and d.AffID = @AffID
	order by a.DomainName
	

GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffClientSel] TO [vnteam]