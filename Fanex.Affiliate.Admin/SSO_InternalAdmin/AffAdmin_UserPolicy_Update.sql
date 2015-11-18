ALTER PROCEDURE [dbo].[AffAdmin_UserPolicy_Update]
(
	@UserID		INT,
	@LicenseeID INT,
	@FunctionID	INT,
	@Policy		TINYINT,
	@ModifyDate	DATETIME = NULL,
	@Creator	INT = NULL
)
/*
	Created: 20151117@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update UserPolicy
	Revision:
*/
AS
BEGIN
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_UserPolicy WITH (ROWLOCK, UPDLOCK)
	SET Policy = @Policy,
		ModifyDate = @ModifyDate,
		Creator = ISNULL(@Creator, Creator)
	WHERE UserID = @UserID
		AND FunctionID = @FunctionID
		AND LicenseeID = @LicenseeID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_UserPolicy_Update] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserPolicy_Update] TO [vnteam]