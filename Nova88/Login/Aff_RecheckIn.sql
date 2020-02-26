/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_RecheckIn]     
	@On_UserID INT,    
	@IsKickedOut BIT = 0 OUTPUT    
AS
/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Original:

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/
SET NOCOUNT ON    
Select @IsKickedOut = 0    
update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()     
where on_userid = @On_UserID    
return     
  
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
