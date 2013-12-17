CREATE Procedure [dbo].[AffAdmin_SystemSettingsSelByName]	
	@Name varchar(50)
AS
/*
Created: 20110222@Johnny
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SName=@Name

GO
GRANT EXECUTE ON [dbo].[AffAdmin_SystemSettingsSelByName] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_SystemSettingsSelByName] TO [vnteam]