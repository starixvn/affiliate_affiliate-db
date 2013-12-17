ALTER Procedure [dbo].[AffAdmin_Logout]      
	@OnUserID int  
AS      
/**    
 * Created by : Johnny    
 * Date   : 2013070723  
 * Task   : Create to process logout of admin on Affiliate admin site.      
 * DB   : DB052.Affiliate_MYM      
 * Revisions :    
 * •    
 * Parameters:    
  @OnUserID: On User ID  
 *      
 */    
    
      
SET NOCOUNT ON      
--Write log to record user logout      
Declare @CustID int, @Username varchar(30), @Creator int, @LoginIP varchar(20), @TypeName varchar(20), @Role varchar(20),  @SubAccID int     
Select @CustID = custid, @LoginIP = IP, @SubAccID=subaccid       
From On_User (nolock) where on_userid = @OnUserID      
  
SELECT @TypeName = case when @SubAccID=6 then 'LogoutAdmin' else 'LogoutAffiliate' end    
      
Delete from On_User where on_userid = @OnUserID      
    
--Write log    
declare @SPName varchar(50), @LogData nvarchar(200)    
select @SPName = OBJECT_NAME(@@ProcID)    
SELECT @LogData =  case when @SubAccID=6 then 'Admin' else 'Affiliate' end + case when isnull(@Username,'') = '' then cast(isnull(@custid,'') as varchar(30)) else isnull(@Username,'') end + ' IP:' + isnull(@LoginIP,'')  
    
select @Creator = case when @SubAccID < 0 then abs(@SubAccID) else @CustID end    
    
EXEC [dbo].[Aff_WriteLog]     
	@Creator = @Creator,    
	@AffID = @CustID,    
	@Typename = @TypeName, -- refer to table LogType    
	@SPName = @SPName,    
	@Details = @LogData,    
	@IP = @LoginIP    

GO
GRANT EXECUTE ON [dbo].[AffAdmin_Logout] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_Logout] TO [vnteam]