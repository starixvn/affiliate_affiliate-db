ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountIns] 
	@FirstName nvarchar(50),
	@LastName nvarchar(50),	
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,
	@GroupID int,	
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS
--Used to create AccAdmin
--In DB02.bodb02 --> DB052.Affiliate_ZZun
SET NOCOUNT ON

/*
Created: 
Task : Add account in User control 
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101112@Henry: add Maxperball161
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213

/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]',@System = 'AFFILIATE', @ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN*/
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
	@pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
	@closed = 0
	
if exists(select 1 from AdminUser with (NOLOCK) where username=@username) 
BEGIN
	SELECT @ErrCode = 2005
	return
END

BEGIN TRANSACTION

	INSERT INTO AdminUser (username, UserPwd, roleid, firstname, lastname, creator, pwdexpiry,closed,GroupId,createdate) 
	VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry,@closed,@GroupID,getdate()) 

	Select @CustID = @@IDENTITY

	
	if @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrCode = 10	
		return
	END

COMMIT TRANSACTION 	

EXEC dbo.AffAdmin_Con_PolicyIns @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID,@IP=@IP


DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName + ' GroupID:' + dbo.Aff_ToString(@GroupID)


EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	
		





