ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Update]
(
	@GroupID	INT,
	@GroupName	NVARCHAR(50) = NULL,
	@GroupDesc	NVARCHAR(50) = NULL,
	@ModifyDate	DATETIME = NULL,
	@DisplayOrder	TINYINT = NULL,
	@Creator	INT = NULL
)
/*
	Created: 20151112@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update GroupInfo
	Revision:
*/
AS
BEGIN
	SELECT @ModifyDate = ISNULL(@ModifyDate, GETDATE())

	UPDATE Aff_GroupInfo WITH (ROWLOCK, UPDLOCK)
	SET GroupName = ISNULL(@GroupName,GroupName),
		GroupDesc = ISNULL(@GroupDesc, GroupDesc),
		ModifyDate = @ModifyDate,
		DisplayOrder = ISNULL(@DisplayOrder, DisplayOrder),
		Creator = ISNULL(@Creator, Creator)
	WHERE GroupID = @GroupID
END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_GroupInfo_Update] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupInfo_Update] TO [vnteam] AS [dbo]