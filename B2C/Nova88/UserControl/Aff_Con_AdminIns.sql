/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminIns] 
	@FirstName nvarchar(50),
	@LastName nvarchar(50),	
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,
	@GroupID int,	
	@IP varchar(15) = '',
	@Language varchar(2)= 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

SET NOCOUNT ON
/*
Created: 
Task : Add account in User control 
DB:  DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101112@Henry: add Maxperball161
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
	- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
	- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
	
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]', @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
	@pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
	@closed = 0
	
if exists(select 1 from Affiliate_User with (NOLOCK) where username=@username) 
BEGIN
	SELECT @ErrMsg =  case @Language
						when 'E' then 'This username is not available. '
						when 'CS' then N'This username is not available. '
						when 'J' then N'This username is not available. '
						else N'This username is not available. '
					end, @ErrCode = 102
	return
END

BEGIN TRANSACTION

	INSERT INTO Affiliate_User (username, UserPwd, roleid, firstname, lastname, creator, pwdexpiry,closed,GroupId,createdate) 
	VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry,@closed,@GroupID,getdate()) 

	Select @CustID = @@IDENTITY

	
	if @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add customer failed.'
							when 'CS' then N'Add customer failed.'
							when 'J' then N'Add customer failed.'
							else N'Add customer failed.'
						end, @ErrCode = 103	
		return
	END

COMMIT TRANSACTION 	

EXEC dbo.Aff_Con_AdminPolicyIns @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID,@IP=@IP


DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName + ' GroupID:' + dbo.Aff_ToString(@GroupID)

GO