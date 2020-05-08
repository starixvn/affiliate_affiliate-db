/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Logout]  
 @On_UserID int,  
 @ServerID int = NULL,  
 @UserName varchar(30) = NULL  
AS  
/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Original:

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88 [RedmineID: #128775]
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
GO