/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_AccountUpdPwd]  
	@CustID		INT,
	@UserID		INT,  
	@OldPwd		NVARCHAR(50) = NULL,
	@OldSalt	VARCHAR(50) = NULL,
	@UserPwd	NVARCHAR(50),   
	@UserSalt	VARCHAR(50), 
	@IP			VARCHAR(20), 
	@ErrCode	INT = 0 OUTPUT
AS  

/*
	Created:
	DB: DBAFF.Affiliate_XXX
	Task: Update user password

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151125@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20190424@Percy: Change server of nested SP AffAdmin_ITAdminUser_Update & nested function AffAdmin_f_AdminUserInfo_Select [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @LicenseeID INT
	SELECT @LicenseeID = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'LicenseeID'

	DECLARE @Users TABLE (UserPwd VARCHAR(50), UserSalt VARCHAR(50))

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql =
	'SELECT UserPwd, UserSalt FROM OPENQUERY(DBCUST,
		''SELECT UserPwd, UserSalt FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @CustID) + ', ' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'

	INSERT INTO @Users (UserPwd, UserSalt)
	EXEC (@sql)

	IF NOT EXISTS (
		SELECT 1 FROM @Users
		WHERE 1 = (CASE WHEN (@OldPwd IS NOT NULL AND UserPwd = @OldPwd) OR @OldPwd IS NULL THEN 1 ELSE 0 END)
				AND 1 = (CASE WHEN (@OldSalt IS NOT NULL AND UserSalt = @OldSalt) OR @OldSalt IS NULL THEN 1 ELSE 0 END))
	BEGIN
		SELECT @ErrCode = 11
		RETURN 
	END

	EXEC DBCUST.bodb_licensee.dbo.AffAdmin_ITAdminUser_Update
		@UserID		= @CustID,
		@UserPwd	= @UserPwd,
		@UserSalt	= @UserSalt

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID),
			@Detail = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
  
	EXEC dbo.Aff_WriteLog
		@Creator	= @UserID,
		@Typename	= 'Password', -- refer to table LogType
		@SPName		= @SPName,
		@Details	= @Detail,
		@IP			= @IP
END
GO