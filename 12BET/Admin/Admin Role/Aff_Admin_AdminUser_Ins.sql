/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Ins]
	@UserId			INT
	,@UserName		VARCHAR(50)
	,@FirstName		NVARCHAR(50) = NULL
	,@LastName		NVARCHAR(50) = NULL
	,@UserPwd		VARCHAR(100)
	,@UserSalt		VARCHAR(100)
	,@RoleId		TINYINT
	,@Closed		BIT
	,@Market		XML = NULL
	,@IP			VARCHAR(50) = ''
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Add new User

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]

	Param's Explanation:
		@Market:
			<root>
				<r MarketId="en" Status="1"/>
				<r MarketId="vi" Status="0"/>
			</root>
*/

BEGIN
	SET NOCOUNT ON

	-- Check permission
	EXEC dbo.Aff_CheckPermission
		@CustId		= @UserId
		,@FuncName	= '[AdminRole]'
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	-- Check exists username
	IF EXISTS (SELECT 1 FROM dbo.Users WITH (NOLOCK) WHERE UserName = @UserName AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This username is already exists!'
		RETURN
	END

	DECLARE @UserMarket TABLE (MarketId NVARCHAR(10), Status BIT)
	INSERT INTO @UserMarket (MarketId, Status)
	SELECT t.c.value('@MarketId', 'NVARCHAR(10)') AS MarketId
		,t.c.value('@Status', 'BIT') AS Status
	FROM @Market.nodes('root/r') t(c)
	OPTION (OPTIMIZE FOR (@Market = NULL))

	-- Insert process
	DECLARE @CustId INT

	BEGIN TRY
		INSERT INTO dbo.Users (UserName,RoleId,FirstName,LastName,UserPwd,UserSalt,Creator,Closed)
		VALUES (@UserName,@RoleId,@FirstName,@LastName,@UserPwd,@UserSalt,@UserId,@Closed)

		SELECT @CustId = SCOPE_IDENTITY()

		INSERT INTO dbo.UserMarket (CustId,MarketId,Creator)
		SELECT @CustId,MarketId,@UserId
		FROM @UserMarket
		WHERE Status = 1
	END TRY
	BEGIN CATCH
		DELETE dbo.Users WHERE CustId = @CustId
		DELETE dbo.UserMarket WHERE CustId = @CustId

		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
	
	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
END
GO