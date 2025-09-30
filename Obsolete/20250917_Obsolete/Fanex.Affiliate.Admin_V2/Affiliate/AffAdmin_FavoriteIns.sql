/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_FavoriteIns]  
	@UserId			int,
	@AdminUserName	VARCHAR(50),
	@AffId			int,  
	@ErrCode		int = 0 OUTPUT 
AS

/*    
	Created: 20130826@Joseph
	Task : Insert an affiliate to AdminFavorite
	DB:    
	Original:[Aff_FavoriteIns]      
	Revisions:
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]
                
	Param's Explanation:      
	. @UserId : admin id      
*/ 
 
SET NOCOUNT ON  

if exists(select 1 from AdminFavorite with (nolock) where AdminID = @UserId and AffID = @AffID AND AdminName = @AdminUserName)  
begin  
	select @ErrCode = 2006  
	return
end  
  
insert into AdminFavorite(AdminID, AffID, AdminName)  
values (@UserId, @AffID, @AdminUserName)  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrCode = 2007  
 return  
END
GO