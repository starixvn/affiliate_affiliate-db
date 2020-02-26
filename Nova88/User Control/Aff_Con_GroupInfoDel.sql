/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_GroupInfoDel]
	@GroupID int,
	@Language VARCHAR(2)= 'E', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT ,
	@UserID int,
	@IP varchar(15) = ''
AS
/*
DB: DBAFFN8G-Affiliate_N8G	
Revisions:
	-- DB03.BODB02 --> DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/

SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

IF exists (select 1 from affiliate_user with (NOLOCK) where GroupID = @GroupID) 
BEGIN
	Select @ErrMsg = 	case @Language 
					when 'E' then N' This group has customer belong to, so you cannot delete!'
					when 'CS' then N' This group has customer belong to, so you cannot delete!'
					else N' This group has customer belong to, so you can not delete!'
			end, @ErrCode = 102
	return
END	
	
DELETE FROM AffGroupPolicy where GroupID=@GroupID
DELETE FROM AffGroupInfo where GroupID=@GroupID


	--Write log
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)
	

GO 