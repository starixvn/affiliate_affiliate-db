/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AdminUser_Upd]
	@UserId		INT
	,@CustId	INT
	,@UserName	VARCHAR(50) = NULL
	,@FirstName	NVARCHAR(50) = NULL
	,@LastName	NVARCHAR(50) = NULL
	,@UserPwd	VARCHAR(100) = NULL
	,@UserSalt	VARCHAR(100) = NULL
	,@RoleId	TINYINT = NULL
	,@Closed	BIT = NULL
	,@Function	XML = NULL
	,@Market	XML = NULL
	,@IP		VARCHAR(50) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin - Admin Role - Update User Info

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]

	Param's Explanation:
		@Market:
			<root>
				<r MarketId="en" Status="1"/>
				<r MarketId="vi" Status="0"/>
			</root>
		@Function:
			<root>
				<r FuncId="1" Policy="1"/>
				<r FuncId="1" Policy="0"/>
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
	IF EXISTS (SELECT 1 FROM dbo.Users WITH (NOLOCK) WHERE UserName = @UserName AND CustId <> @CustId AND IsDeleted = 0)
	BEGIN
		SELECT @ErrCode = 100, @ErrMsg = 'This username is already exists!'
		RETURN
	END

	DECLARE @UserFunction TABLE (FuncId SMALLINT, Policy TINYINT)
	DECLARE @UserMarket TABLE (MarketId NVARCHAR(10), Status BIT)

	IF @Function IS NOT NULL
	BEGIN
		INSERT INTO @UserFunction (FuncId, Policy)
		SELECT t.c.value('@FuncId', 'SMALLINT') AS FuncId
			,t.c.value('@Policy', 'TINYINT') AS Policy
		FROM @Function.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@Function = NULL))

		IF EXISTS (SELECT 1 FROM @UserFunction WHERE Policy IS NULL OR Policy NOT IN (0, 1, 3))
		BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Function setting is invalid!'
			RETURN
		END
	END

	IF @Market IS NOT NULL
	BEGIN
		INSERT INTO @UserMarket (MarketId, Status)
		SELECT t.c.value('@MarketId', 'NVARCHAR(10)') AS MarketId
			,t.c.value('@Status', 'BIT') AS Status
		FROM @Market.nodes('root/r') t(c)
		OPTION (OPTIMIZE FOR (@Market = NULL))
	END

	-- Update process
	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)
	SELECT  @OldData =
		'UserId='	+ CONVERT(VARCHAR(15), CustId) + ',' +
		'UserName='	+ UserName + ',' +
		'FirstName='+ ISNULL(FirstName, '') + ',' +
		'LastName='	+ ISNULL(LastName, '') + ',' +
		'RoleId='	+ CONVERT(VARCHAR(5), RoleId) + ',' +
		'Closed='	+ CONVERT(VARCHAR(1), Closed)
	FROM dbo.Users WITH (NOLOCK)
	WHERE CustId = @CustId AND IsDeleted = 0

	DECLARE @OldFunction XML, @OldMarket XML
			,@NewFunction XML, @NewMarket XML

	BEGIN TRY
		UPDATE dbo.Users WITH (ROWLOCK)
		SET UserName	= ISNULL(@UserName, UserName)
			,FirstName	= ISNULL(@FirstName, FirstName)
			,LastName	= ISNULL(@LastName, LastName)
			,UserPwd	= ISNULL(@UserPwd, UserPwd)
			,UserSalt	= ISNULL(@UserSalt, UserSalt)
			,RoleId		= ISNULL(@RoleId, RoleId)
			,Closed		= ISNULL(@Closed, Closed)
		WHERE CustId	= @CustId

		IF @Function IS NOT NULL
		BEGIN
			SELECT @OldFunction = (
				SELECT FuncId AS '@FuncId', Policy AS '@Policy'
				FROM dbo.UserFunction WITH (NOLOCK)
				WHERE CustId = @CustId
				FOR XML PATH('row'), ROOT('root')
			)

			UPDATE uf WITH (ROWLOCK)
			SET uf.Policy = ISNULL(t.Policy, 0)
			FROM dbo.UserFunction uf
				LEFT JOIN @UserFunction t ON uf.FuncId = t.FuncId
			WHERE uf.CustId = @CustId

			SELECT @NewFunction = (
				SELECT FuncId AS '@FuncId', Policy AS '@Policy'
				FROM dbo.UserFunction WITH (NOLOCK)
				WHERE CustId = @CustId
				FOR XML PATH('row'), ROOT('root')
			)
		END

		IF @Market IS NOT NULL
		BEGIN
			SELECT @OldMarket = (
				SELECT	m.MarketId AS '@MarketId'
						,m.MarketName AS '@MarketName'
						,m.DisplayName AS '@DisplayName'
						,CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS '@Status'
				FROM dbo.Market m WITH (NOLOCK)
					LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON um.MarketId = m.MarketId AND um.CustId = @CustId
				FOR XML PATH('row'), ROOT('root')
			)

			DELETE dbo.UserMarket WITH (ROWLOCK, UPDLOCK) WHERE CustId = @CustId

			INSERT INTO dbo.UserMarket (CustId,MarketId,Creator)
			SELECT @CustId,MarketId,@UserId
			FROM @UserMarket
			WHERE Status = 1

			SELECT @NewMarket = (
				SELECT	m.MarketId AS '@MarketId'
						,m.MarketName AS '@MarketName'
						,m.DisplayName AS '@DisplayName'
						,CASE WHEN um.MarketId IS NULL THEN 0 ELSE 1 END AS '@Status'
				FROM dbo.Market m WITH (NOLOCK)
					LEFT JOIN dbo.UserMarket um WITH (NOLOCK) ON um.MarketId = m.MarketId AND um.CustId = @CustId
				FOR XML PATH('row'), ROOT('root')
			)
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	SELECT  @NewData =
		'UserId='	+ CONVERT(VARCHAR(15), CustId) + ',' +
		'UserName='	+ UserName + ',' +
		'FirstName='+ ISNULL(FirstName, '') + ',' +
		'LastName='	+ ISNULL(LastName, '') + ',' +
		'RoleId='	+ CONVERT(VARCHAR(5), RoleId) + ',' +
		'Closed='	+ CONVERT(VARCHAR(1), Closed)
	FROM dbo.Users WITH (NOLOCK)
	WHERE CustId = @CustId AND IsDeleted = 0

	IF @OldData = @NewData
		SELECT @OldData = NULL, @NewData = NULL

	SELECT @OldData = COALESCE(@OldData + ',', '') + 'FunctionPolicy=' + CONVERT(VARCHAR(MAX), @OldFunction)
			,@NewData = COALESCE(@NewData + ',', '') + 'FunctionPolicy=' + CONVERT(VARCHAR(MAX), @NewFunction)
		
	SELECT @OldData = COALESCE(@OldData + ',', '') + 'MarketPolicy=' + CONVERT(VARCHAR(MAX), @OldMarket)
			,@NewData = COALESCE(@NewData + ',', '') + 'MarketPolicy=' + CONVERT(VARCHAR(MAX), @NewMarket)

	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@SPName	= @SPName
		,@OldData	= @OldData
		,@NewData	= @NewData
		,@IP		= @IP
END
GO