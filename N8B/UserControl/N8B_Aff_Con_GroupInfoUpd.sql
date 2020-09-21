/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_GroupInfoUpd]
	@GroupID int,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*
DB: DBAFFN8B-Affiliate_N8B	
Revisions:
	-- DB03.BODB02 -->DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
*/

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from AffGroupInfo with (NOLOCK) where Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
	Select @ErrMsg = 	case @Language 
						when 'E' then N'This group name is already used.'
						when 'CS' then N'This group name is already used.'
						else N'This group name is already used.'
				end, @ErrCode = 101	
	return
END 
ELSE
BEGIN
	Update AffGroupInfo set GroupName=isnull(@GroupName,GroupName),GroupDesc=isnull(@GroupDesc,GroupDesc),Modifydate=getdate(),Creator=@Userid where GroupID=@GroupID	
		
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Update groupinfo:' + dbo.Aff_ToString(@GroupID)

END

GO