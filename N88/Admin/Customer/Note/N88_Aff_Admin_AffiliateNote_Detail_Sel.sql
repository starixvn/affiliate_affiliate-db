/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Detail_Sel]
	@AffID		INT
	,@NoteID	INT
AS

/*
	Created: 20190614@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Customer - Note - View a note

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	SET NOCOUNT ON

	SELECT NoteID, Note
	FROM dbo.AdminNotes WITH (NOLOCK)
	WHERE AffID = @AffID AND NoteID = @NoteID
END
GO