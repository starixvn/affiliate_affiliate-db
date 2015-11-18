ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Insert]
(
	@LicenseeID	INT,
	@GroupName	NVARCHAR(50),
	@GroupDesc	NVARCHAR(50),
	@CreateDate	DATETIME = NULL,
	@ModifyDate	DATETIME = NULL,
	@DisplayOrder	TINYINT = 1,
	@Creator	INT = NULL,
	@GroupID	INT = NULL OUTPUT
)
/*
	Created: 20151112@Victor
	DB: DBLIC/bodb_licensee
	Remark: Insert GroupInfo
	Revision:
*/
AS
BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())

	INSERT INTO Aff_GroupInfo (LicenseeID, GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
	SELECT @LicenseeID, @GroupName, @GroupDesc, @CreateDate, @ModifyDate, @DisplayOrder, @Creator

	SELECT @GroupID = SCOPE_IDENTITY()
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_GroupInfo_Insert] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupInfo_Insert] TO [vnteam]