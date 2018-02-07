/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_NoteSel]	
	@LicenseeID INT,
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
	- 20180205@Percy: Change INNER JOIN to LEFT JOIN to show LAP username [RedmineID: #90545]

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/

BEGIN
	SET NOCOUNT ON

	SELECT 
		[Noteid], [Note] as [Content], [UpdatedDate], N.AffID, [Updatedby], ISNULL(U.username, '') AS UpdateName
	FROM AdminNotes N WITH (NOLOCK)
		LEFT JOIN dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) U ON U.UserID=N.UPDATEDBY
	WHERE AffID = @AffID and
		(@NoteId is null or NoteId = @NoteId)
END
GO