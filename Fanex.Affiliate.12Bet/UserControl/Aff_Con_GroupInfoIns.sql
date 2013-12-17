Alter PROCEDURE [dbo].[Aff_Con_GroupInfoIns]
	@GroupID int output,
	@GroupName nvarchar(50)='',
	@GroupDesc nvarchar(50)='',
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@IP varchar(15) = '' 
As
/*DB03.BODB02 -->DB052.Affiliate_12BET*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
If @ErrCode <> 0
	RETURN
--end
IF exists (select 1 from AffGroupInfo with (NOLOCK) where system = 'AFFILIATE' and GroupName = @GroupName)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'This group name is already used.'
					when 'CS' then N'This group name is already used.'
					else N'This group name is already used.'
			end, @ErrCode = 102
	return
END
BEGIN TRANSACTION
	INSERT INTO AffGroupInfo(Groupname, GroupDesc, System, CreateDate,ModifyDate,Creator)
		VALUES (@GroupName, @GroupDesc, 'AFFILIATE', getdate(),getdate(),@UserID)
	
	SELECT @GroupID=@@IDENTITY
	Insert into AffGroupPolicy(GroupID,FuncID,Policy,Createdate,ModifyDate,Creator)
		Select @GroupID as GroupID,FuncID,0 as policy,getdate() as createdate,
			getdate() as modifydate, @UserID as creator
		from AffFunctionInfo with (nolock) where system = 'AFFILIATE'
	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION
		select @ErrMsg = case @Language 
							when 'E' then 'Add group failed.'
							when 'CS' then N'Add group failed.'
							when 'J' then N'Add group failed.'
							else N'Add group failed.'
						end, @ErrCode = 103
		return
	END
COMMIT TRANSACTION

	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] add groupinfo:' + dbo.Aff_ToString(@GroupID)
	
	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData	

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoIns] TO [vnteam]
go

GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoIns] TO [bodbAdminNet]