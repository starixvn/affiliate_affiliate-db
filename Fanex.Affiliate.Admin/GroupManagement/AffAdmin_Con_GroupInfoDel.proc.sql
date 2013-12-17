ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoDel]
	@GroupID int,
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@System = 'AFFILIATE'
If @ErrCode <> 0
	RETURN*/
--end

IF exists (select 1 from AdminUser with (NOLOCK) where GroupID = @GroupID) 
BEGIN
	Select @ErrCode = 14
	return
END	
	
DELETE FROM AffGroupPolicy where GroupID=@GroupID
DELETE FROM AffGroupInfo where GroupID=@GroupID


	--Write log
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)

	
	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=0,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData	



