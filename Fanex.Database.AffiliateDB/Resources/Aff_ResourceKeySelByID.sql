 ALTER PROCEDURE [dbo].[Aff_ResourceKeySelByID]	
	@ID uniqueidentifier
AS
/*
Created: 20110221@Peter
Task : Get 1 Resource From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From RefResources (nolock)
where ResourceID=@ID

GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeySelByID] TO [vnteam]