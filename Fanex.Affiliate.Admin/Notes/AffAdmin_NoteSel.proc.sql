ALTER Procedure [dbo].[AffAdmin_NoteSel]	
	@AffID int,
	@NoteId int = null
AS
/*
Created: 20090122@TrangLe
Task : List Notes for Affiliate
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/
SET NOCOUNT ON

SELECT 
	[Noteid], [Note] as [Content], [UpdatedDate], N.AffID, [Updatedby], U.username as UpdateName
FROM AdminNotes N WITH (NOLOCK)
	INNER JOIN AdminUser U WITH (NOLOCK) ON U.CUSTID=N.UPDATEDBY
WHERE AffID = @AffID and
	(@NoteId is null or NoteId = @NoteId)


