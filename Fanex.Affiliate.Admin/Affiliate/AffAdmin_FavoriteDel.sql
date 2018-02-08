/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_FavoriteDel]  
	@UserId		int,
	@AdminUserName	VARCHAR(50),
	@AffId		int,
	@ErrCode	int = 0 OUTPUT
AS

/*    
	Created: 20130826@Joseph
	Task : delete an affiliate from AdminFavorite
	DB:    
	Original:[Aff_FavoriteDel]      
	Revisions:          
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

	Param's Explanation:      
	. @UserId : admin id      
*/ 

SET NOCOUNT ON  
   
if Not exists(select 1 from AdminFavorite with (nolock) where AdminID = @UserId and AffID = @AffID AND AdminName = @AdminUserName)  
begin  
 select @ErrCode = 10021  
 return  
end  
  
delete AdminFavorite  with (rowlock, updlock)
where AdminID = @UserId and AffID = @AffID  AND AdminName = @AdminUserName
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrCode = 10020  
 return  
END
GO