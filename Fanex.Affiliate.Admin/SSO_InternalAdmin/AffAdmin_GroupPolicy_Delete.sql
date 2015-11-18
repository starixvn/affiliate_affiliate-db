ALTER PROCEDURE [dbo].[AffAdmin_GroupPolicy_Delete]
(
	@GroupID	INT
)
/*
	Created: 20151111@Victor
	DB: DBLIC/bodb_licensee
	Remark: Delete GroupPolicy by GroupID
	Revision:
*/
AS
BEGIN
	DELETE FROM dbo.Aff_GroupPolicy WHERE GroupID = @GroupID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_GroupPolicy_Delete] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupPolicy_Delete] TO [vnteam]