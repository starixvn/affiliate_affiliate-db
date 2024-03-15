/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Detail_Sel]
	@AffID		INT
	,@NoteID	INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Customer - Note - View a note

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT NoteID, Note
	FROM dbo.AdminNotes WITH (NOLOCK)
	WHERE AffID = @AffID AND NoteID = @NoteID
END
GO