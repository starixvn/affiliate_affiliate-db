/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Newsletter_Sel]
	@NewsletterId INT = 0
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@NRows INT = 0 OUTPUT
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - Select

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	SELECT @NewsletterId = ISNULL(@NewsletterId, 0)

	DECLARE @RowStart INT, @RowEnd INT
	SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	IF @NewsletterId <> 0
	BEGIN
		SELECT NewsletterId, FileName, FileSize, UploadDate, EffectiveFromDate, EffectiveToDate, Language 
		FROM dbo.Newsletter WITH(NOLOCK) WHERE NewsletterId = @NewsletterId
		RETURN
	END

	SELECT @NRows = COUNT(1)
	FROM dbo.Newsletter WITH(NOLOCK)

	SELECT h.NewsletterId, h.FileName, h.FileSize, h.UploadDate, h.EffectiveFromDate, h.EffectiveToDate, h.Language 
	FROM
	(
		SELECT n.NewsletterId, n.FileName, n.FileSize, n.UploadDate, n.EffectiveFromDate, n.EffectiveToDate , n.Language, ROW_NUMBER() OVER(ORDER BY n.NewsletterId DESC) AS Rn
		FROM dbo.Newsletter n WITH(NOLOCK)
	) AS h
	WHERE h.Rn BETWEEN @RowStart AND @RowEnd
	ORDER BY h.Rn ASC
END
GO