/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Detail_Sel]
	@AffID		INT
	,@NoteID	INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Customer - Note - View a note

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT NoteID, Note
	FROM dbo.AdminNotes WITH (NOLOCK)
	WHERE AffID = @AffID AND NoteID = @NoteID
END
GO