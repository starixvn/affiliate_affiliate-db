Alter PROCEDURE [dbo].[Aff_Con_GroupInfoUpd]
	@GroupID int,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 -->DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from AffGroupInfo with (NOLOCK) where system = 'AFFILIATE' and Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
	Select @ErrMsg = case @Language 
				when 'en-US' then 'Error! This affiliate does not exist!'
				when 'zh-CN' then N'這個群組名稱已經被使用'
				when 'zh-TW' then N'这个群组名称已经被使用'
				else N'Error! This affiliate does not exist!'
			end, @ErrCode = 101	
	return
END 
ELSE
BEGIN
	Update AffGroupInfo set GroupName=isnull(@GroupName,GroupName),GroupDesc=isnull(@GroupDesc,GroupDesc),Modifydate=getdate(),Creator=@Userid where GroupID=@GroupID	
		
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Update groupinfo:' + dbo.Aff_ToString(@GroupID)


	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData	
END



GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoUpd] TO [vnteam]
go

GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoUpd] TO [bodbAdminNet]