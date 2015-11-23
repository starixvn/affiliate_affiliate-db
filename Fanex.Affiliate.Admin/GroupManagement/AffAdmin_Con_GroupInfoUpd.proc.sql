ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoUpd]
	@GroupID int,
	@LicenseeID INT,
	@GroupName nvarchar(50)=null,
	@GroupDesc nvarchar(50)=null,
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 -->DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
-- 20151113@Victor: Implement SSO from Internal Admin to Affiliate Admin [Redmine: #41437]
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN*/
--end

IF exists (select 1 from dbo.AffAdmin_f_GroupInfo_Select('', @LicenseeID) where Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
	Select @ErrCode = 21	
	return
END 
ELSE
BEGIN
	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupInfo_Update @GroupID = @GroupID, @GroupName = @GroupName, @GroupDesc = @GroupDesc, @Creator = @UserID
		
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





