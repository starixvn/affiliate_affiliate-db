CREATE PROCEDURE [dbo].[Aff_CountrySel]
	
AS
	Select CountryID, CountryName
	From Country nolock

GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CountrySel] TO [vnteam]