/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminIns] 
	@FirstName NVARCHAR(50),
	@LastName NVARCHAR(50),	
	@UserName NVARCHAR(50),
	@UserPwd NVARCHAR(50) = '',
	@CustID INT OUTPUT,
	@UserID INT,
	@GroupID INT,	
	@IP VARCHAR(15) = '',
	@Language VARCHAR(2)= 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task : Add account in User control 
	Original:

	Revisions:
		- 20080213@Phuc: Check permission for account site
		- 20090218@PhuongDao: Check username2 
		- 20100713@Peter : Remove Write Log on IBC DB
		- 20101112@Henry: add Maxperball161
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET	
		- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET	
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]
	
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