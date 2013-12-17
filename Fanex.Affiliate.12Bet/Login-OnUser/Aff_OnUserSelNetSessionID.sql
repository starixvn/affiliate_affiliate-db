ALTER PROCEDURE [dbo].[Aff_OnUserSelNetSessionID]  
 @On_UserID int,     
 @NetSessionID varchar(30) OUTPUT 
AS  
/*
Created: 20090316@Ken
Task : Get NetSessionID from table On_User
DB: DB052.Affiliate_12Bet

Revisions:	
*/
SET NOCOUNT ON
SELECT @NetSessionID = ''

SELECT @NetSessionID = NetSessionID
FROM On_User WITH(NOLOCK) 
WHERE On_UserID = @On_UserID

GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_OnUserSelNetSessionID] TO [VNTeam] 