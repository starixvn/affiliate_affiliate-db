ALTER Procedure [dbo].[Aff_SporttypeSelByAff]  
	@AffId int
AS    
  
/*  
Task : Get List sport type by affiliate ID  
DB: DB052.Affiliate_12BET  
Original:[Aff_CustomerSelAffiliate]    
Revisions:        
*/    
SET NOCOUNT ON  

Declare @GroupId int

select @GroupId = GroupId from AffInfo nolock where AffId = @AffId

select SportId, SportName
from SportType nolock
where SportId in (select distinct SportType from GroupSetting nolock where GroupId = @GroupId)

GO
GRANT EXECUTE ON [dbo].[Aff_SporttypeSelByAff] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SporttypeSelByAff] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_SporttypeSelByAff] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SporttypeSelByAff] TO [vnteam]