ALTER PROCEDURE [dbo].[AffAdmin_GroupPolicy_Insert]
(
	@GroupID		INT,
	@FunctionIDs	VARCHAR(1000),
	@Policy			TINYINT,
	@CreateDate		DATETIME = NULL,
	@ModifyDate		DATETIME = NULL,
	@Creator		INT = NULL
)
/*
	Created: 20151112@Victor
	DB: DBLIC/bodb_licensee
	Remark: Insert GroupPolicy
	Revision:
*/
AS
BEGIN
	DECLARE @FunctionList TABLE (FunctionID INT)
	INSERT INTO @FunctionList (FunctionID)
	SELECT CAST(val AS INT) FROM bodb02.dbo.Lrf_f_StringSplit(@FunctionIDs, ',')

	SELECT @CreateDate = ISNULL(@CreateDate, GETDATE()),
		@ModifyDate = ISNULL(@ModifyDate, GETDATE())
	
	INSERT INTO Aff_GroupPolicy (GroupID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT @GroupID, FunctionID, @Policy, @CreateDate, @ModifyDate, @Creator
	FROM @FunctionList

END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_GroupPolicy_Insert] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupPolicy_Insert] TO [vnteam]