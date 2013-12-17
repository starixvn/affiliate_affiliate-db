-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_FavoriteIns]  
 @UserId int,  
 @AffId int,  
 @ErrCode int = 0 OUTPUT 
AS  
/*    
Created: 20130826@Joseph
Task : Insert an affiliate to AdminFavorite
DB:    
Original:[Aff_FavoriteIns]      
Revisions:          
                
Param's Explanation:      
. @UserId : admin id      
*/   
SET NOCOUNT ON  
/*--Favorite is no need to check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@AdminId,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,   
   
If @ErrCode <> 0  
 RETURN  
*/  
if exists(select 1 from AdminFavorite with (nolock) where AdminID = @UserId and AffID = @AffID)  
begin  
 select @ErrCode = 2006  
  return  
end  
  
insert into AdminFavorite(AdminID, AffID)  
values (@UserId, @AffID)  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrCode = 2007  
 return  
END  


GO
GRANT EXECUTE ON [dbo].[AffAdmin_FavoriteIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_FavoriteIns] TO [vnteam]