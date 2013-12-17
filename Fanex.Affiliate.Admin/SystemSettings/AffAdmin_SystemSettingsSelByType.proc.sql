CREATE Procedure [dbo].[AffAdmin_SystemSettingsSelByType]	
	@Type varchar(50)=NULL
AS
/*
Created: 20110221@Peter
Task : Get All Settings By Type
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

SELECT [SID], [SName], [SValue],[Type],[Description]
FROM SystemSettings S WITH (NOLOCK)		
where Type =coalesce(@Type,Type)

GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelByType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_SystemSettingsSelByType] TO [vnteam]