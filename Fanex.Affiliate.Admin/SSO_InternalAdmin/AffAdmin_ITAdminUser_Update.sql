ALTER PROCEDURE [dbo].[AffAdmin_ITAdminUser_Update]
(
	@UserID		INT,
	@UserPwd	VARCHAR(50) = NULL,
	@UserSalt	VARCHAR(50) = NULL,
	@FirstName	NVARCHAR(50) = NULL,
	@LastName	NVARCHAR(50) = NULL,
	@Status		VARCHAR(30) = NULL
)
/*
	Created: 20151125@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update IT Admin user
	Revision:
*/
AS
BEGIN
	UPDATE Users WITH (ROWLOCK, UPDLOCK) 
	SET UserPwd = ISNULL(@UserPwd, UserPwd),
		UserSalt = ISNULL(@UserSalt, UserSalt),
		FirstName = ISNULL(@FirstName, FirstName),
		LastName = ISNULL(@LastName, LastName),
		[Status] = ISNULL(@Status, [Status])
	WHERE UserID = @UserID

END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_ITAdminUser_Update] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ITAdminUser_Update] TO [vnteam]