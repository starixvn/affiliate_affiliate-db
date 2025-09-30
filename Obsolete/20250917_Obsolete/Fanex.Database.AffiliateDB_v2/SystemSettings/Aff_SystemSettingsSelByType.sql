  ALTER PROCEDURE [dbo].[Aff_SystemSettingsSelByType]	
	@Type varchar(50)=NULL
AS
/*
Created: 20110221@Peter
Task : Get All Settings By Type
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

SELECT [SID], [SName], [SValue],[Type],[Description]
FROM SystemSettings S WITH (NOLOCK)		
where Type =coalesce(@Type,Type)
	
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbDownlineNet]	
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbDownlineNetView]	
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByType] TO [vnteam]