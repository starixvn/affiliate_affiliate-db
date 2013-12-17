
/****** Object:  StoredProcedure [dbo].[Aff_Logout]    Script Date: 09/24/2009 04:35:50 ******/
ALTER PROCEDURE [dbo].[Aff_Logout]  
 @On_UserID int,  
 @ServerID int = NULL,  
 @UserName varchar(30) = NULL  
AS  
/*  
Created:   
Task : Admin logout  
DB: DB052.Affiliate_12Bet
Original:  
  
Revisions:  
	- 20090915@Hung: Create to process logout of admin on Affiliate admin site.  
  
Param's Explanation:  
*/  
  
SET NOCOUNT ON  
--Write log to record user logout  
Declare @CustID int, @Creator int, @LoginIP varchar(20), @TypeName varchar(20), @Role varchar(20),  @SubAccID int 
Select @CustID = custid, @ServerID = coalesce(@ServerID,ServerID,''), @LoginIP = IP, @SubAccID=subaccid   
From On_User (nolock) where on_userid = @On_UserID  
  
select @ServerID=null

SELECT @TypeName = case when @SubAccID=6 then 'LogoutAdmin' else 'LogoutAffiliate' end
  

Delete from On_User where on_userid = @On_UserID  

--Write log
declare @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)
SELECT @LogData =  case when @SubAccID=6 then 'Admin' else 'Affiliate' end + case when isnull(@UserName,'') = '' then cast(isnull(@custid,'') as varchar(30)) else isnull(@Username,'') end + ' IP:' + isnull(@LoginIP,'') + ' Logout ServerID:' + CAST(isnull(@ServerID,'') as nvarchar(20))    


select @Creator = case when @SubAccID < 0 then abs(@SubAccID) else @CustID end

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Creator,
	@AffID = @CustID,
	@Typename = @TypeName, -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @LoginIP 
	
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Logout] TO [vnteam]
GO

   
  