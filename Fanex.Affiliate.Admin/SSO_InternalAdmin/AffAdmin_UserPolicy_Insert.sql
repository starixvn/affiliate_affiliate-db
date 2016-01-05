ALTER PROCEDURE [dbo].[AffAdmin_UserPolicy_Insert]
(
	@UserID			INT,
	@LicenseeID		INT,
	@FunctionID		INT,
	@Policy			TINYINT,
	@CreateDate		DATETIME = NULL,
	@ModifyDate		DATETIME = NULL,
	@Creator		INT = NULL
)
/*
	Created: 20151118@Victor
	DB: DBLIC/bodb_licensee
	Remark: Insert UserPolicy
	Revision:
*/
AS
BEGIN
	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())
	
	INSERT INTO Aff_UserPolicy (UserID, LicenseeID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT @UserID, @LicenseeID, @FunctionID, @Policy, @CreateDate, @ModifyDate, @Creator

END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserPolicy_Insert] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserPolicy_Insert] TO [vnteam] AS [dbo]