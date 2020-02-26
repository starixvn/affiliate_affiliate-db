/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
/*
DB: DBAFFN8G-Affiliate_N8G	
Revisions:
-- DB03.BODB02 -->DB052.Affiliate_12BET 
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
-- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
IF exists (select 1 from AffGroupInfo with (NOLOCK) where GroupName = @GroupName)
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N'This group name is already used.'
					when 'CS' then N'This group name is already used.'
					else N'This group name is already used.'
			end, @ErrCode = 102
	return
END
BEGIN TRANSACTION
	INSERT INTO AffGroupInfo(Groupname, GroupDesc, CreateDate,ModifyDate,Creator)
		VALUES (@GroupName, @GroupDesc, getdate(),getdate(),@UserID)
	
	SELECT @GroupID=@@IDENTITY
	Insert into AffGroupPolicy(GroupID,FuncID,Policy,Createdate,ModifyDate,Creator)
		Select @GroupID as GroupID,FuncID,0 as policy,getdate() as createdate,
			getdate() as modifydate, @UserID as creator
		from AffFunctionInfo with (nolock)
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
	
GO