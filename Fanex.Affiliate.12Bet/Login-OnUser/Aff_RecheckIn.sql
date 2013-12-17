ALTER PROCEDURE [dbo].[Aff_RecheckIn]     
 @On_UserID int,    
 @IsKickedOut bit = 0 OUTPUT    
AS    
SET NOCOUNT ON    
    
--Original:On_UserUpd    
----------------------------------    
--Allow multi-login, will remove after testing    
Select @IsKickedOut = 0    
update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()     
where on_userid = @On_UserID    
return     
  
--------------------------------    
    
if exists (select 1 from on_user with (NOLOCK) where On_UserID = @On_UserID and isKickedOut=1)    
BEGIN    
 Select @IsKickedOut=1    
END    
else    
BEGIN    
 Select @IsKickedOut = 0    
 update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()     
 where on_userid = @On_UserID    
     
 IF @@ROWCOUNT = 0    
  Select @IsKickedOut=1    
END

GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_RecheckIn] TO [VNTeam] 