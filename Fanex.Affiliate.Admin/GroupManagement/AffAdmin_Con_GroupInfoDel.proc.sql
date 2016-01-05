ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoDel]
	@GroupID int,
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@UserID int,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
/*

Revision:
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
	-- 20151022@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/

--Check permission for account site: @phuc20080213
/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@System = 'AFFILIATE'
If @ErrCode <> 0
	RETURN*/
--end
SET NOCOUNT ON

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'


IF EXISTS (SELECT 1 FROM dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) where GroupID = @GroupID) 
BEGIN
	SELECT @ErrCode = 14
	RETURN
END	
	
EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupPolicy_Delete @GroupID=@GroupID
EXEC DBLIC.bodb_licensee.dbo.AffAdmin_GroupInfo_Delete @GroupID = @GroupID


--Write log
DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
SELECT @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)

	
EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=0,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData