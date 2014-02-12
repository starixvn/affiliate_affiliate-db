ALTER PROCEDURE [dbo].[Aff_AffiliateSelLogType]  
   
AS  
/*  
 Created: 20100423@Jacob  
 Task : Get all log type  
 DB: DB052.Affiliate_ZZun  
 Revisions:  
  - 20100423@Jacob initialize  
    
 Param's Explanation:  
  
*/  
SET NOCOUNT ON;  
   
SELECT [TypeID]  
      ,[TypeName]  
      ,[Description]  
  FROM [LogType]  

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelLogType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelLogType] TO [vnteam]
  
