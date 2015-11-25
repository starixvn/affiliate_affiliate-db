ALTER PROCEDURE [dbo].[AffAdmin_ITAdminUser_Insert]
(
	@LicenseeID	INT,
	@Username	VARCHAR(50),
	@UserPwd	VARCHAR(50),
	@Status		VARCHAR(30) = 'Open',
	@CreateDate	DATETIME = NULL,
	@Creator	INT = NULL,
	@ErrCode	INT = 0 OUTPUT, 
	@UserID		INT OUTPUT
)
/*
	Created: 20151125@Victor
	DB: DBLIC/bodb_licensee
	Remark: Insert IT Admin user
	Revision:
*/
AS
BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE())

	SELECT TOP 1 @UserID = UserID FROM dbo.Users WITH (NOLOCK) WHERE Username LIKE @Username AND isInternal = 0

	IF EXISTS (SELECT 1 FROM Aff_LicenseeUser WHERE UserID = @UserID AND LicenseeID = @LicenseeID)
	BEGIN
		SELECT @ErrCode = 1
		RETURN
	END

	IF @UserID IS NULL
	BEGIN
		INSERT INTO dbo.Users (Username, UserPwd, UserSalt, UserRole, FirstName, LastName, [Status], Creator, CreateDate, LicenseeName, isInternal)
		SELECT @Username, @UserPwd, '', 'Admin', '', '', @Status, @Creator, @CreateDate, NULL, 1

		SELECT @UserID = SCOPE_IDENTITY()
	END

	IF @@ERROR != 0
	BEGIN
		SELECT @ErrCode = 2
		RETURN
	END

	DELETE FROM Aff_LicenseeUser WHERE UserID = @UserID

	INSERT INTO Aff_LicenseeUser (LicenseeID, UserID, GroupID, IsActive, ModifyDate, ModifyBy)
	SELECT l.LicenseeID, @UserID, g.GroupID, 1, @CreateDate, @Creator
	FROM Aff_LicenseeInfo l WITH (NOLOCK) 
		INNER JOIN Aff_GroupInfo g WITH (NOLOCK) ON g.LicenseeID = l.LicenseeID AND g.GroupName LIKE 'Aff_IT_Dept'
	WHERE IsActive = 1

END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_ITAdminUser_Insert] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ITAdminUser_Insert] TO [vnteam]