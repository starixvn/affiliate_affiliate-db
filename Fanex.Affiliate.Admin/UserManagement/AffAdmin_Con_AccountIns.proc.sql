ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountIns] 
	@UserName nvarchar(50),
	@UserPwd nvarchar(50) = '',
	@UserSalt varchar(50) = '',
	@CustID int OUTPUT,
	@UserID int,	
	@IP varchar(15) = '',
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT
AS
--Used to create AccAdmin
--In DB02.bodb02 --> DB052.Affiliate_ZZun
SET NOCOUNT ON

/*
Created: 
Task : Add account in User control 
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
	- 20090218@PhuongDao: Check username2 
	- 20100713@Peter : Remove Write Log on IBC DB
	- 20101112@Henry: add Maxperball161
	- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
	- 20151120@Victor: Implement SSO from Internal Admin to Affiliate Admin site
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213

/*EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]',@System = 'AFFILIATE', @ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN*/
--end

DECLARE @LicenseeID INT
SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName LIKE 'LicenseeID'

DECLARE @AddErrCode INT = 0

EXEC DBLIC.bodb_licensee.dbo.AffAdmin_ITAdminUser_Insert @LicenseeID = @LicenseeID, @Username = @Username, @UserPwd = @UserPwd, @UserSalt = @UserSalt, @Creator = @UserID, @ErrCode = @AddErrCode OUTPUT, @UserID = @CustID OUTPUT

	
IF (@AddErrCode = 1)
BEGIN
	SELECT @ErrCode = 2005
	RETURN
END
	
IF @AddErrCode = 2
BEGIN
	SELECT @ErrCode = 10	
	RETURN
END

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName


EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData
GO
GRANT EXECUTE ON [dbo].[AffAdmin_Con_AccountIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_Con_AccountIns] TO [vnteam] AS [dbo]