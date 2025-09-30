CREATE PROCEDURE [dbo].[Aff_MarketSel]
	
AS
	Select MarketId, MarketName
	From Market nolock

GO
GRANT EXECUTE ON [dbo].[Aff_MarketSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_MarketSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_MarketSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MarketSel] TO [vnteam]