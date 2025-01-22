/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_AdminInsFromExisted]
	@username VARCHAR(30),
	@GroupId INT,
	@creator INT,
	@IP VARCHAR(50) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@Language VARCHAR(2) = 'E'
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Create AccAdmin from existed Admin

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @creator
										,@FuncName = '[UserControl]'
										,@ErrCode = @ErrCode OUTPUT
										,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	DECLARE @custid INT
		   ,@roleid INT
		   ,@Closed BIT
		   ,@Password VARCHAR(40)
		   ,@FirstName NVARCHAR(50)
		   ,@LastName NVARCHAR(50)
		   ,@pwdexpiry DATETIME

	SELECT
		@custid = CustId
	   ,@roleid = RoleId
	   ,@Password = UserPwd
	   ,@FirstName = FirstName
	   ,@LastName = LastName
	   ,@pwdexpiry = PwdExpiry
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
	WHERE UserName = @username
	AND RoleId BETWEEN 5 AND 10

	SELECT @custid = ISNULL(@custid, 0)
	   ,@Closed = 0

	IF @custid = 0
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN 'Invalid username.'
				WHEN 'CS' THEN N'Invalid username.'
				WHEN 'J' THEN N'Invalid username.'
				ELSE N'Invalid username.'
			END
		   ,@ErrCode = 101
		RETURN
	END
	ELSE
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM Affiliate_User WITH (NOLOCK)
			WHERE UserName = @Username
		)
		BEGIN
			SELECT
				@ErrMsg =
				CASE @Language
					WHEN 'E' THEN 'This user has been existed as an affiliate admin before.'
					WHEN 'CS' THEN N'This user has been existed as an affiliate admin before.'
					WHEN 'J' THEN N'This user has been existed as an affiliate admin before.'
					ELSE N'This user has been existed as an affiliate admin before.'
				END
			   ,@ErrCode = 102
			RETURN
		END
		ELSE
		BEGIN
			-- add existed admin
			BEGIN TRANSACTION
				INSERT INTO Affiliate_User (CreateDate, Creator, GroupId, Closed, UserName, UserPwd, RoleId, PwdExpiry, FirstName, LastName)
				VALUES (GETDATE(), @creator, @groupid, @Closed, @username, @Password, @roleid, @pwdexpiry, @FirstName, @LastName)

				SELECT @custID = @@identity
				SELECT @custID, @GroupId

				INSERT INTO AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
					-- 0 is default value of the member policy  when create new admin 
				SELECT
					@Custid AS custid
					,FuncId
					,0 AS Policy
					,GETDATE() AS Createdate
					,GETDATE() AS ModifyDate
					,@creator AS Creator
				FROM AffGroupPolicy WITH (NOLOCK)
				WHERE GroupId = @GroupID

				IF @@error <> 0
				BEGIN
					ROLLBACK TRANSACTION
					SELECT
						@ErrMsg =
						CASE @Language
							WHEN 'E' THEN 'Add customer failed.'
							WHEN 'CS' THEN N'Add customer failed.'
							WHEN 'J' THEN N'Add customer failed.'
							ELSE N'Add customer failed.'
						END
					   ,@ErrCode = 103
					RETURN
				END
			COMMIT TRANSACTION
		END
	END

	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = 'NEW Affiliate Admin from Existed Admin custid:' + CONVERT(VARCHAR(20), @custid) + ' username:' + @UserName + ' GroupID:' + CONVERT(VARCHAR(20), @groupid)
END
GO