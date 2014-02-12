ALTER PROCEDURE [dbo].[Aff_SystemSettingsSelByName]	
	@Name varchar(50)
AS
/*
Created: 20110222@Johnny
Task : Get 1 Settings From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SName=@Name

GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByName] TO [vnteam]