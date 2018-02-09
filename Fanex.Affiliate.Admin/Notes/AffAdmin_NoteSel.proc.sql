/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_NoteSel]	
	@AffID		INT,
	@NoteId		INT = null
AS

/*
Created: 20090122@TrangLe
Task : List Notes for Affiliate
DB: DB052.Affiliate_MYM
Original:
Revisions:
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/

BEGIN
	SET NOCOUNT ON

	SELECT 
		[Noteid], [Note] as [Content], [UpdatedDate], N.AffID, [Updatedby], N.UpdatedByName AS UpdateName
	FROM AdminNotes N WITH (NOLOCK)
	WHERE AffID = @AffID and
		(@NoteId is null or NoteId = @NoteId)
END
GO