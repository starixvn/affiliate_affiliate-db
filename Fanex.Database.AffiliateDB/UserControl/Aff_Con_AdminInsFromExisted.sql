Alter PROCEDURE [dbo].[Aff_Con_AdminInsFromExisted]
	@username varchar(30),
	@GroupId int,
	@creator int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(5) = 'en-US'
AS
/*
create AccAdmin from existed Admin
DB03.bodb02 --> DB052.Affiliate_ZZun
Revisions:
	- VinhTrinh@20100507: insert closed field to table AdminUser
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
*/
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@creator,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

Declare @custid int, @roleid int, @Closed bit,@Password varchar(40),@FirstName nvarchar(50),@LastName nvarchar(50),@pwdexpiry datetime
select @custid = custid, @roleid = roleid,@Password=userpwd,
		@FirstName=FirstName,@LastName=LastName,@pwdexpiry=pwdexpiry
from bodb02.dbo.customer c with (nolock)	
where username = @username and roleid between 5 and 10

select @custid = isnull(@custid, 0)
		, @Closed = 0
if @custid = 0
BEGIN
	select @ErrMsg = case @Language 
						when 'en-US' then 'Invalid username.'
						when 'zh-CN' then N'無效的使用者名稱'
						when 'zh-TW' then N'无效的使用者名称'
						else N'Invalid username.'
					end, @ErrCode = 101	
	return	
END
else
BEGIN
		if exists (select 1 from AdminUser with (nolock) where username = @username)
		BEGIN
			select @ErrMsg = case @Language 
						when 'en-US' then 'This user has been existed as an affiliate admin before.'
						when 'zh-CN' then N'這個使用者已經存在如同之前合作夥伴的管理者'
						when 'zh-TW' then N'这个使用者已经存在如同之前合作伙伴的管理者'
						else N'This user has been existed as an affiliate admin before.'
					end, @ErrCode = 102	
			return
		END
		ELSE
		BEGIN
			-- add existed admin
			BEGIN TRANSACTION 
			
			INSERT INTO AdminUser
				(createdate, creator, groupid, Closed,username,UserPwd,RoleId,PwdExpiry,FirstName,LastName)
			VALUES				
				( getdate(), @creator, @groupid, @Closed,@username,@Password,@RoleId,@PwdExpiry,@FirstName,@LastName)
			Select @custID=@@IDENTITY
				
			select @custID, @GroupId
			
			INSERT INTO AffMemberPolicy(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
			-- 0 is default value of the member policy  when create new admin 
			SELECT @Custid as custid,FuncID,0 as Policy,getdate() as Createdate,getdate() as ModifyDate,@creator as Creator 
			FROM AffGroupPolicy with(nolock)
			WHERE GroupId=@GroupID
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
		END
	
END

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW Affiliate Admin from Existed Admin custid:' + convert(varchar(20), @custid) + ' username:' + @UserName + ' GroupID:' + convert(varchar(20),@groupid)


EXEC [dbo].[Aff_WriteLog]
		@Creator=@creator,	
		@AffID=@custid,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	


GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminInsFromExisted] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminInsFromExisted] TO [bodbAdminNet]