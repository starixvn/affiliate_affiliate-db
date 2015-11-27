ALTER PROCEDURE [dbo].[AffAdmin_AdminUser_UpdateGroup]
(
	@UserID		INT,
	@LicenseeID	INT,
	@GroupID	INT,
	@ModifyDate	DATE = NULL,
	@ModifyBy	INT = NULL
)
/*
	Created: 20151125@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update Admin user group
	Revision:
*/
AS
BEGIN
	UPDATE Aff_LicenseeUser WITH (ROWLOCK, UPDLOCK) 
	SET GroupID = @GroupID,
		ModifyDate = ISNULL(@ModifyDate, GETDATE()),
		@ModifyBy = ISNULL(@ModifyBy, ModifyBy)
	WHERE UserID = @UserID
		AND LicenseeID = @LicenseeID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_AdminUser_UpdateGroup] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AdminUser_UpdateGroup] TO [vnteam]