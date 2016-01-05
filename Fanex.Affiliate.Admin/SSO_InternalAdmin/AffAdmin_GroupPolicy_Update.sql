ALTER PROCEDURE [dbo].[AffAdmin_GroupPolicy_Update]
(
	@GroupID	INT,
	@FunctionID	INT,
	@Policy		TINYINT,
	@ModifyDate	DATETIME = NULL,
	@Creator	INT = NULL
)
/*
	Created: 20151117@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update GroupPolicy
	Revision:
*/
AS
BEGIN
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_GroupPolicy WITH (ROWLOCK, UPDLOCK)
	SET Policy = @Policy,
		ModifyDate = @ModifyDate,
		Creator = ISNULL(@Creator, Creator)
	WHERE GroupID = @GroupID
		AND FunctionID = @FunctionID
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_GroupPolicy_Update] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupPolicy_Update] TO [vnteam] AS [dbo]