/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_AccountIns] 
	@UserName	NVARCHAR(50),
	@UserPwd	NVARCHAR(50) = '',
	@UserSalt	VARCHAR(50) = '',
	@CustID		INT OUTPUT,
	@UserID		INT,	
	@IP			VARCHAR(15) = '',
	@Language	VARCHAR(5) = 'en-US',
	@ErrCode	INT = 0 OUTPUT
AS

/*
	Created:
	Task: Add account in User control
	DB: DBAFF.Affiliate_XXX
	Original:

	Revisions:
		- 20080213@Phuc: Check permission for account site
		- 20090218@PhuongDao: Check username2
		- 20100713@Peter : Remove Write Log on IBC DB
		- 20101112@Henry: add Maxperball161
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151120@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested SP AffAdmin_ITAdminUser_Insert [RedmineID: #103658]
	
	Param's Explanation:
		• @ErrCode:
			= 0: super create master successfully.
			> 0: Specific Error.
		• @ErrMsg: Error description.
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @AddErrCode INT = 0

	EXEC DBCUST.bodb_licensee.dbo.AffAdmin_ITAdminUser_Insert
		@LicenseeID = @LicenseeID,
		@Username	= @Username,
		@UserPwd	= @UserPwd,
		@UserSalt	= @UserSalt,
		@Creator	= @UserID,
		@ErrCode	= @AddErrCode OUTPUT,
		@UserID		= @CustID OUTPUT
	
	IF @AddErrCode = 1
	BEGIN
		SELECT @ErrCode = 2005
		RETURN
	END
	ELSE IF @AddErrCode = 2
	BEGIN
		SELECT @ErrCode = 10	
		RETURN
	END

	DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName

	EXEC dbo.Aff_WriteLog
		@Creator	= @UserID,
		@AffID		= @CustID,
		@Typename	= 'UserControl',
		@SPName		= @SPName,
		@IP			= @IP,
		@Details	= @LogData
END
GO