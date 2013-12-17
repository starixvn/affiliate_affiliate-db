-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_FavoriteDel]  
 @UserId int,  
 @AffId int,  	
 @ErrCode int = 0 OUTPUT
AS  
/*    
Created: 20130826@Joseph
Task : delete an affiliate from AdminFavorite
DB:    
Original:[Aff_FavoriteDel]      
Revisions:          
                
Param's Explanation:      
. @UserId : admin id      
*/   
SET NOCOUNT ON  
/*--Favorite is no need to check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserId,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
*/    
if Not exists(select 1 from AdminFavorite with (nolock) where AdminID = @UserId and AffID = @AffID)  
begin  
 select @ErrCode = 10021  
 return  
end  
  
delete AdminFavorite  
where AdminID = @UserId and AffID = @AffID  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrCode = 10020  
 return  
END  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_FavoriteDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_FavoriteDel] TO [vnteam]