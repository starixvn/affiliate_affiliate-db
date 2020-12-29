/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Sel]
	@AffId		INT
	,@PageSize	INT = 50
	,@PageIndex	INT = 1
	,@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Customer - Note - View all notes

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblNote TABLE (NoteId INT PRIMARY KEY)
	INSERT INTO @tblNote (NoteId)
	SELECT NoteId FROM dbo.AdminNotes WITH (NOLOCK) WHERE AffId = @AffId

	SELECT @NRows = COUNT(1) FROM @tblNote

	IF @NRows = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT NoteId, Note, UpdatedBy, UpdatedName, UpdatedDate
	FROM (
		SELECT n.NoteId, an.Note, an.UpdatedBy, an.UpdatedName, an.UpdatedDate
			,ROW_NUMBER() OVER(ORDER BY an.UpdatedDate DESC) AS RN
		FROM @tblNote n
			CROSS APPLY (
				SELECT an.Note, an.UpdatedBy, u.UserName AS UpdatedName, an.UpdatedDate
				FROM dbo.AdminNotes an WITH (NOLOCK)
					LEFT JOIN dbo.Users u WITH (NOLOCK) ON an.UpdatedBy = u.CustId
				WHERE n.NoteID = an.NoteID
			) AS an
	) AS r
	WHERE RN BETWEEN @RowStart AND @RowEnd
	ORDER BY RN
END
GO