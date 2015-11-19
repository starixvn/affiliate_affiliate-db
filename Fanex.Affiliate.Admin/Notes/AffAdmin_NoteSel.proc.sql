ALTER Procedure [dbo].[AffAdmin_NoteSel]	
	@LicenseeID INT,
	@AffID int,
	@NoteId int = null
AS
/*
Created: 20090122@TrangLe
Task : List Notes for Affiliate
DB: DB052.Affiliate_MYM
Original:
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/
SET NOCOUNT ON

SELECT 
	[Noteid], [Note] as [Content], [UpdatedDate], N.AffID, [Updatedby], U.username as UpdateName
FROM AdminNotes N WITH (NOLOCK)
	INNER JOIN dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) U ON U.UserID=N.UPDATEDBY
WHERE AffID = @AffID and
	(@NoteId is null or NoteId = @NoteId)


