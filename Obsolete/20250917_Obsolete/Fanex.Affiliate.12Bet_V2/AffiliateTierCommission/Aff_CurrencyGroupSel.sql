ALTER Procedure [Aff_CurrencyGroupSel]
	@AffId int = null
AS

if(@AffId is null)
Begin
	Select GroupId, GroupName, CurrencyList, Description
	From CurrencyGroup nolock	
	return
End

Select distinct GroupId, GroupName, CurrencyList, Description
From CurrencyGroup c with(nolock)
	inner join (select g.CurrencyGroup
				from AffInfo a with(nolock)
					inner join GroupSetting g with (nolock) on a.GroupId = g.GroupID
				where a.AffId = @AffId
				union
				select 1 as currencyGroup--Default all group for affiliate				
				) t on c.GroupId = t.CurrencyGroup
				
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyGroupSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyGroupSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CurrencyGroupSel] TO [vnteam]
