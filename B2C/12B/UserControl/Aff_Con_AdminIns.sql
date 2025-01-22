/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_AdminIns] 
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),	
	@UserName NVARCHAR(50),
	@UserPwd NVARCHAR(50) = '',
	@CustID INT OUTPUT,
	@UserID INT,
	@GroupID INT,	
	@IP VARCHAR(50) = '',
	@Language VARCHAR(2)= 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task : Add account in User control 
	Original:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
	
	Param's Explanation:
	• @ErrCode:
		= 0: super create master successfully.
		> 0: Specific Error.
  
	• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON
	--Check permission for account site: @phuc20080213
	EXEC [dbo].[Aff_Con_CheckPermission] @CustID = @UserID
										,@FuncName = '[UserControl]'
										,@ErrCode = @ErrCode OUTPUT
										,@ErrMsg = @ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	--end

	DECLARE @pwdexpiry DATETIME
		   ,@roleid INT
		   ,@closed BIT

	SELECT @roleid = 6
	   ,@pwdexpiry = DATEADD(MONTH, 1, current_timestamp)
	   ,@closed = 0

	IF EXISTS(
		SELECT 1
			FROM Affiliate_User WITH (NOLOCK)
			WHERE UserName = @Username
	)
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN 'This username is not available. '
				WHEN 'CS' THEN N'This username is not available. '
				WHEN 'J' THEN N'This username is not available. '
				ELSE N'This username is not available. '
			END
		   ,@ErrCode = 102
		RETURN
	END

	BEGIN TRANSACTION
		INSERT INTO Affiliate_User (UserName, UserPwd, RoleId, FirstName, LastName, Creator, PwdExpiry, Closed, GroupId, CreateDate)
		VALUES (@username, @UserPwd, @roleid, @FirstName, @LastName, @UserID, @pwdexpiry, @closed, @GroupID, GETDATE())

		SELECT @CustID = @@identity

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

	EXEC dbo.Aff_Con_AdminPolicyIns @CustID = @CustID
								   ,@UserID = @UserID
								   ,@GroupID = @GroupID
								   ,@IP = @IP


	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@CustID) + ' username:' + @UserName + ' GroupID:' + dbo.Aff_ToString(@GroupID)
END
GO