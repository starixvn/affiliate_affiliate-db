ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountUpd]
	@CustID int,
	@UserID int,
	@GroupID int,
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS
BEGIN

	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	--DB02.BODB02 -->  DB052.Affiliate_ZZun
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
	-- 20151127@Victor: Implement SSO from Internal Admin to Affiliate Admin site

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

	EXEC [dbo].[AffAdmin_Con_CheckPermission] @LicenseeID = @LicenseeID, @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
	If @ErrCode <> 0
		RETURN
	--end
	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_AdminUser_UpdateGroup @UserID=@CustID, @LicenseeID = @LicenseeID, @GroupID=@GroupID, @ModifyBy = @UserID

	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@groupid)


	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=@CustID,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData	


END
GO
--depends on SPs:
--[dbo].[AffAdmin_Con_CheckPermission]



