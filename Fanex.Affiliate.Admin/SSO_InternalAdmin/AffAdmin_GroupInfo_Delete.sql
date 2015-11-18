ALTER PROCEDURE [dbo].[AffAdmin_GroupInfo_Delete]
(
	@GroupID	INT
)
/*
	Created: 20151111@Victor
	DB: DBLIC/bodb_licensee
	Remark: Delete GroupInfo by GroupID
	Revision:
*/
AS
BEGIN
	DELETE FROM dbo.Aff_GroupInfo WHERE GroupID = @GroupID
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_GroupInfo_Delete] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupInfo_Delete] TO [vnteam]