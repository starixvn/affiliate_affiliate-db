ALTER PROCEDURE [dbo].[Aff_SystemSettingsSelByID]	
	@ID int
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SID=@ID

GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByID] TO [vnteam]