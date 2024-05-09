/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateNote_Sel]
	@AffID		INT
	,@PageSize	INT = 50
	,@PageIndex	INT = 1
	,@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Customer - Note - View all notes

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblNote TABLE (NoteID INT PRIMARY KEY)
	INSERT INTO @tblNote (NoteID)
	SELECT NoteID FROM dbo.AdminNotes WITH (NOLOCK) WHERE AffID = @AffID

	SELECT @NRows = COUNT(1) FROM @tblNote

	IF @NRows = 0
		RETURN

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT NoteID, Note, UpdatedBy, UpdatedName, UpdatedDate
	FROM (
		SELECT n.NoteID, an.Note, an.UpdatedBy, an.UpdatedName, an.UpdatedDate, ROW_NUMBER() OVER(ORDER BY an.UpdatedDate DESC) AS RN
		FROM @tblNote n
			CROSS APPLY (
				SELECT an.Note, an.UpdatedBy, u.Username AS UpdatedName, an.UpdatedDate
				FROM dbo.AdminNotes an WITH (NOLOCK)
					LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON an.UpdatedBy = u.custid
				WHERE n.NoteID = an.NoteID
			) AS an
	) AS r
	WHERE RN BETWEEN @RowStart AND @RowEnd
	ORDER BY RN
END
GO