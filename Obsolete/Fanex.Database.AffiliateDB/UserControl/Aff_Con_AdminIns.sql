ALTER PROCEDURE [dbo].[Aff_Con_AdminIns] 
	@FirstName nvarchar(50),
	@LastName nvarchar(50),	
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,
	@GroupID int,	
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
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
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]',@System = 'AFFILIATE', @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
	@pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
	@closed = 0
	
if exists(select 1 from AdminUser with (NOLOCK) where username=@username) 
BEGIN
	SELECT @ErrMsg = case @Language 
						when 'en-US' then 'This username is not available.'
						when 'zh-CN' then N'這個使用者名稱不存在'
						when 'zh-TW' then N'这个使用者名称不存在'
						else N'This username is not available.'
					end, @ErrCode = 102
	return
END

BEGIN TRANSACTION

	INSERT INTO AdminUser (username, UserPwd, roleid, firstname, lastname, creator, pwdexpiry,closed,GroupId,createdate) 
	VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry,@closed,@GroupID,getdate()) 

	Select @CustID = @@IDENTITY

	
	if @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
						when 'en-US' then 'Add customer failed.'
						when 'zh-CN' then N'這個使用者名稱不存在'
						when 'zh-TW' then N'这个使用者名称不存在'
						else N'Add customer failed.'
					end, @ErrCode = 103	
		return
	END

COMMIT TRANSACTION 	

EXEC dbo.Aff_Con_AdminPolicyIns @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID,@IP=@IP


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
		

GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminIns] TO [vnteam]