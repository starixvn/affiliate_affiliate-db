/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Newsletter_Sel]
	@NewsletterId INT = 0
	,@PageIndex INT = 1
	,@PageSize INT = 50
	,@Date DATETIME = NULL
	,@NRows INT = 0 OUTPUT
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - Select

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]
		- 20240819@Eddie: Hide Hindi Market [RedmineID: #209409]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	SELECT @NewsletterId = ISNULL(@NewsletterId, 0)

	DECLARE @RowStart INT, @RowEnd INT
	SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	IF @NewsletterId <> 0
	BEGIN
		SELECT NewsletterId, FileName, FileSize, UploadDate, EffectiveFromDate, EffectiveToDate, Language, m.MarketName AS LanguageName
		FROM dbo.Newsletter n WITH(NOLOCK) 
			INNER JOIN dbo.Market m WITH(NOLOCK) ON n.Language = m.MarketID AND m.MarketID <> 'hi'
		WHERE NewsletterId = @NewsletterId
		RETURN
	END

	SELECT @NRows = COUNT(1)
	FROM dbo.Newsletter n WITH(NOLOCK)
	WHERE (@Date IS NULL OR (@Date BETWEEN n.EffectiveFromDate AND n.EffectiveToDate))

	SELECT h.NewsletterId, h.FileName, h.FileSize, h.UploadDate, h.EffectiveFromDate, h.EffectiveToDate, h.Language, h.LanguageName
	FROM
	(
		SELECT n.NewsletterId, n.FileName, n.FileSize, n.UploadDate, n.EffectiveFromDate, n.EffectiveToDate , n.Language, m.MarketName AS LanguageName, ROW_NUMBER() OVER(ORDER BY n.UploadDate DESC) AS Rn
		FROM dbo.Newsletter n WITH(NOLOCK)
			INNER JOIN dbo.Market m WITH(NOLOCK) ON n.Language = m.MarketID AND m.MarketID <> 'hi'
		WHERE (@Date IS NULL OR (@Date BETWEEN n.EffectiveFromDate AND n.EffectiveToDate))
	) AS h
	WHERE h.Rn BETWEEN @RowStart AND @RowEnd
	ORDER BY h.Rn ASC
END
GO