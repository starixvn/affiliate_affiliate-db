 ALTER PROCEDURE [dbo].[Aff_GetPrefixByAff]    
 @AffID int,  
 @Prefix varchar(3)='$' OUTPUT     
AS    
/*  
 Created: 20110330@VinhTrinh   
 Task : [description of SP]    
 DB: DB052.Affiliate_ZZun1  
 Revisions:      
       - Get Prefix by AffId  
 Param's Explanation:    
*/    
SET NOCOUNT ON  
  
Select @Prefix = isnull(Prefix, '$')  
from AffInfo a with(nolock)  
 left join Exchange e with(nolock) on a.Currency = e.ExchangeID  
where AffId = @AffId  
  
GO
GRANT EXECUTE ON [dbo].[Aff_GetPrefixByAff] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetPrefixByAff] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetPrefixByAff] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetPrefixByAff] TO [vnteam]