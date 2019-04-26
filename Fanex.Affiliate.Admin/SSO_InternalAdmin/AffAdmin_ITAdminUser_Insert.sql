/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ITAdminUser_Insert]
	@LicenseeID	INT,
	@Username	VARCHAR(50),
	@UserPwd	VARCHAR(50),
	@UserSalt	VARCHAR(50),
	@Status		VARCHAR(30) = 'Open',
	@CreateDate	DATETIME = NULL,
	@Creator	INT = NULL,
	@ErrCode	INT = 0 OUTPUT, 
	@UserID		INT OUTPUT
AS

/*
	Created: 20151125@Victor
	DB: DBCUST.bodb_licensee
	Remark: Insert IT Admin user
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE())
	SELECT @UserID = NULL

	SELECT TOP 1 @UserID = UserID FROM dbo.Users WITH (NOLOCK) WHERE Username LIKE @Username AND isInternal = 0

	IF EXISTS (SELECT 1 FROM dbo.Aff_LicenseeUser WITH (NOLOCK) WHERE UserID = @UserID AND LicenseeID = @LicenseeID)
	BEGIN
		SELECT @ErrCode = 1
		RETURN
	END

	IF @UserID IS NULL
	BEGIN
		INSERT INTO dbo.Users (Username, UserPwd, UserSalt, UserRole, FirstName, LastName, [Status], Creator, CreateDate, LicenseeName, isInternal)
		SELECT @Username, @UserPwd, @UserSalt, 'Admin', '', '', @Status, @Creator, @CreateDate, NULL, 0

		SELECT @UserID = SCOPE_IDENTITY()
	END

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 2
		RETURN
	END

	DELETE dbo.Aff_LicenseeUser WITH (ROWLOCK, UPDLOCK)
	WHERE UserID = @UserID

	INSERT INTO dbo.Aff_LicenseeUser (LicenseeID, UserID, GroupID, IsActive, ModifyDate, ModifyBy)
	SELECT l.LicenseeID, @UserID, g.GroupID, 1, @CreateDate, @Creator
	FROM dbo.Aff_LicenseeInfo l WITH (NOLOCK) 
		INNER JOIN dbo.Aff_GroupInfo g WITH (NOLOCK) ON g.LicenseeID = l.LicenseeID AND g.GroupName LIKE 'Aff_IT_Dept'
	WHERE IsActive = 1
END
GO