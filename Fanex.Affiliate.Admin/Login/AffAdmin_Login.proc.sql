ALTER PROCEDURE [dbo].[AffAdmin_Login]         
 @UserName varchar(50),        
 @UserPwd varchar(50),        
 @LoginIP varchar(20),         
 @From nvarchar(200) = '',        
 @CustID int OUTPUT,        
 @NetSessionID varchar(30),    
 @OnUserID int = 0 OUTPUT,         
 @ErrCode int = 0 OUTPUT,        
 @IsIT bit = 0 OUTPUT        
AS        
SET NOCOUNT ON        
/*
Created: 20130802@Johnny
Task : Admin login
DB: AoncashUAT

Revisions:
	- 20130802@Johnny : Create
Param's Explanation:
	• @ErrCode:  
	• @ErrMsg: Error description.
*/    
        
declare @LogData nvarchar(200),        
 @db_userpwd nvarchar(50),        
 @failedcount tinyint, @closed bit,         
 @SPName varchar(50),        
 @GroupName nvarchar(50),        
 @GroupID int        
        
select @SPName = OBJECT_NAME(@@ProcID)        
SELECT @LogData = '', @ErrCode = 0 -- initial value        
        
SELECT @CustID = custid, @db_userpwd = UserPwd, @failedcount = IsNull(logincount, 0),        
  @UserName = username, @closed = closed, @GroupName = GroupName, @GroupID = au.GroupId        
FROM  AdminUser au with (NOLOCK)         
  inner join AffGroupInfo g with (nolock) on au.GroupId = g.GroupId        
WHERE username = @UserName        
        
        
IF @@ROWCOUNT = 0 -- user not found        
 SELECT  @ErrCode = 101,        
  @CustID = 0,        
  @LogData = 'Admin:' + @UserName + ' IP:' + @LoginIP + ' Result:Failed(User_Not_Found) From:' + @From        
ELSE IF @UserPWD <> @db_userpwd        
BEGIN        
 SELECT @ErrCode = 101,        
  @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(Password) From:' + @From        
        
 IF @failedcount = 5  -- already failed for 5 times, this is 6th time , LOCK THE A/C          
 BEGIN        
          
   UPDATE AdminUser with (rowlock, updlock) SET closed = 1 WHERE custid = @custid        
           
  select @LogData = 'The A/C is closed due to 5 wrong password attempts'         
   , @ErrCode = 102        
          
          
 END        
 ELSE        
  UPDATE AdminUser with (rowlock, updlock) SET logincount = @failedcount + 1 WHERE custid = @custid        
END        
        
IF (@LogData = '')        
BEGIN         
         
 IF @closed = 1        
  SELECT  @ErrCode = 103,        
   @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(A/C_Closed) From:' + @From         
 ELSE        
 BEGIN        
  UPDATE AdminUser with (rowlock, updlock)        
  SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0        
  WHERE custid = @custid        
        
  SET @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Success From:' + @From        
 END        
END        
        
 IF @LogData <> ''        
 BEGIN        
           
  EXEC [dbo].[Aff_WriteLog] @Creator = @CustID, @AffID = 0, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData        
 END        
        
Declare @GroupIT varchar(50)        
        
select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()        
        
if(@GroupID = @GroupIT)        
 select @IsIT = 1     
     
    
--Login onuser      
update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID      
      
insert into on_user        
 (custid, NetSessionID, on_sessionid, ServerId, IsKickedout, IP, SubAccID, reload_time)        
values        
 (@CustID, @NetSessionid, 0, 0, 0, @LoginIP, 6, current_timestamp)     
    
Select @OnUserID = SCOPE_IDENTITY()

GO
GRANT EXECUTE ON [dbo].[AffAdmin_Login] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_Login] TO [vnteam]